import { catchError } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';
import * as SparkMD5 from 'spark-md5';

import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';
import { ProgressInfo, PromiseTaskQueue } from 'core-app/shared/helpers/promise-task-queue';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

export class WorkPackageEdocFileUploadService {
  constructor(
    private readonly http:HttpClient,
    private readonly halResourceService:HalResourceService,
  ) {}

  public startUpload = async (resource:WorkPackageEdocFolderResource, file:File) => {
    const url = resource.create_file?.href;
    if (!url) return Promise.reject(new Error('Missing href for create_file action'));

    // 获取文件切片
    const chunks = this.getFileChunks(file);

    // 计算文件MD5值
    const md5 = await this.getFileMd5ByChunks(chunks);

    return new Promise<{
      md5:string;
      chunks:Blob[];
      resource:WorkPackageEdocFileResource;
    }>((resolve, reject) => {
      this.http.request(
        'post',
        url,
        {
          body: {
            md5,
            file_name: file.name,
            file_size: file.size,
            content_type: file.type,
          },
          withCredentials: true,
          responseType: 'json',
        },
      ).pipe(
        catchError((error) => {
          reject(error);
          throw error;
        }),
      ).subscribe((result) => {
        resolve({
          md5,
          chunks,
          resource: this.halResourceService.createHalResource<WorkPackageEdocFileResource>(result),
        });
      });
    });
  };

  public uploadChunk = async (resource:WorkPackageEdocFileResource, chunk:Blob, index:number):Promise<WorkPackageEdocFileResource> => {
    const url = resource.upload?.href;
    if (!url) return Promise.reject(new Error('Missing href for upload action'));

    const form = new FormData();

    form.append('chunk_index', index.toString());

    form.append('chunk_file', chunk);

    return new Promise((resolve, reject) => {
      this.http.request(
        'post',
        url,
        {
          body: form,
          withCredentials: true,
          responseType: 'json',
        },
      ).pipe(
        catchError((error) => {
          reject(error);
          throw error;
        }),
      ).subscribe((result) => {
        resolve(this.halResourceService.createHalResource<WorkPackageEdocFileResource>(result));
      });
    });
  };

  public upload = async (
    folder:WorkPackageEdocFolderResource,
    file:File,
    config?:{
      onProgress?:(info:ProgressInfo) => void;
      onComplete?:() => void;
      onError?:(error:Error) => void;
    },
  ) => {
    if (!folder.create_file) return Promise.reject(new Error('Missing href for create_file action'));

    const { chunks, resource } = await this.startUpload(folder, file);

    if (resource.status === 1) return resource;
    if (resource.status === -1) throw new Error('Upload failed');

    const { onProgress, onComplete, onError } = (config || {});

    const queue = new PromiseTaskQueue();

    queue.onProgress(onProgress);

    queue.onComplete(onComplete);

    queue.onError(onError);

    chunks.forEach((chunk, index) => {
      queue.add((lastResult:WorkPackageEdocFileResource|undefined, setComplete, setError) => {
        if (lastResult && lastResult.status === 1) return Promise.resolve(setComplete());
        if (lastResult && lastResult.status === -1) return Promise.reject(setError());
        return this.uploadChunk(resource, chunk, index);
      });
    });

    return queue.start<WorkPackageEdocFileResource>();
  };

  // 文件切片
  getFileChunks = (file:File, chunkSize = 5 * 1024 ** 2) => {
    const chunkTotal = Math.ceil(file.size / chunkSize);

    return new Array(chunkTotal).fill(null).map((_, i) => {
      const start = i * chunkSize;
      const end = ((start + chunkSize) >= file.size) ? file.size : start + chunkSize;
      return file.slice(start, end);
    });
  };

  getFileMd5ByChunks = async (chunks:Blob[]) => {
    const spark = new SparkMD5.ArrayBuffer();

    const queue = new PromiseTaskQueue();

    chunks.forEach((chunk) => {
      queue.add(async () => {
        const buffer = await this.getBufferByBlob(chunk);
        spark.append(buffer);
      });
    });

    await queue.start();

    return spark.end();
  };

  getBufferByBlob = async (blob:Blob):Promise<ArrayBuffer> => new Promise((resolve, reject) => {
    const fileReader = new FileReader();

    fileReader.onload = (e) => {
      resolve(e.target?.result as ArrayBuffer);
    };

    fileReader.onerror = () => {
      reject(new Error('文件读取错误'));
    };

    fileReader.readAsArrayBuffer(blob);
  });

  // 获取文件MD5值
  getFileMd5 = (file:File) => this.getFileMd5ByChunks(this.getFileChunks(file));
}
