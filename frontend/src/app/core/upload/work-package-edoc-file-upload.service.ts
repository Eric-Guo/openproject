import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import * as SparkMD5 from 'spark-md5';

import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';
import { ProgressInfo, PromiseTaskQueue } from 'core-app/shared/helpers/promise-task-queue';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

interface UploadCallbacks {
  onStart?:() => void;
  onProgress?:(info:ProgressInfo) => void;
  onComplete?:() => void;
  onError?:(error:Error) => void;
}

interface UploadStartResult {
  md5:string;
  chunks:Blob[];
  resource:WorkPackageEdocFileResource;
}

interface SparkMd5ArrayBufferInstance {
  append(buffer:ArrayBuffer):void;
  end(raw?:boolean):string;
}

interface SparkMd5Module {
  ArrayBuffer:new () => SparkMd5ArrayBufferInstance;
}

export class WorkPackageEdocFileUploadService {
  private readonly sparkMd5 = SparkMD5 as unknown as SparkMd5Module;

  constructor(
    private readonly http:HttpClient,
    private readonly halResourceService:HalResourceService,
  ) {}

  public startUpload = async (resource:WorkPackageEdocFolderResource, file:File):Promise<UploadStartResult> => {
    const url = resource.create_file?.href;
    if (!url) throw new Error('Missing href for create_file action');

    // 获取文件切片
    const chunks = this.getFileChunks(file);

    // 计算文件MD5值
    const md5 = await this.getFileMd5ByChunks(chunks);

    try {
      const result = await firstValueFrom(this.http.post<unknown>(
        url,
        {
          md5,
          file_name: file.name,
          file_size: file.size,
          content_type: file.type,
        },
        {
          withCredentials: true,
        },
      ));

      return {
        md5,
        chunks,
        resource: this.halResourceService.createHalResource<WorkPackageEdocFileResource>(result),
      };
    } catch (error) {
      throw this.ensureError(error);
    }
  };

  public uploadChunk = async (resource:WorkPackageEdocFileResource, chunk:Blob, index:number):Promise<WorkPackageEdocFileResource> => {
    const url = resource.upload?.href;
    if (!url) throw new Error('Missing href for upload action');

    const form = new FormData();

    form.append('chunk_index', index.toString());

    form.append('chunk_file', chunk);

    try {
      const result = await firstValueFrom(this.http.post<unknown>(
        url,
        form,
        {
          withCredentials: true,
        },
      ));

      return this.halResourceService.createHalResource<WorkPackageEdocFileResource>(result);
    } catch (error) {
      throw this.ensureError(error);
    }
  };

  public upload = async (
    folder:WorkPackageEdocFolderResource,
    file:File,
    config?:UploadCallbacks,
  ):Promise<WorkPackageEdocFileResource> => {
    if (!folder.create_file) throw new Error('Missing href for create_file action');

    const { chunks, resource } = await this.startUpload(folder, file);

    if (resource.status === 1) return resource;
    if (resource.status === -1) throw new Error('Upload failed');

    const {
      onStart,
      onProgress,
      onComplete,
      onError,
    } = config ?? {};

    const queue = new PromiseTaskQueue();

    queue.onStart(onStart);

    queue.onProgress(onProgress);

    queue.onComplete(onComplete);

    queue.onError(onError);

    chunks.forEach((chunk, index) => {
      queue.add((lastResult:WorkPackageEdocFileResource|undefined, setComplete, setError) => {
        if (lastResult?.status === 1) {
          setComplete();
          return Promise.resolve(lastResult);
        }

        if (lastResult?.status === -1) {
          setError();
          return Promise.reject(new Error('Upload failed'));
        }

        return this.uploadChunk(resource, chunk, index);
      });
    });

    return queue.start<WorkPackageEdocFileResource>();
  };

  // 文件切片
  getFileChunks = (file:File, chunkSize = 5 * 1024 ** 2):Blob[] => {
    const chunkTotal = Math.ceil(file.size / chunkSize);

    return new Array(chunkTotal).fill(null).map((_, i) => {
      const start = i * chunkSize;
      const end = ((start + chunkSize) >= file.size) ? file.size : start + chunkSize;
      return file.slice(start, end);
    });
  };

  getFileMd5ByChunks = async (chunks:Blob[]):Promise<string> => {
    const spark = new this.sparkMd5.ArrayBuffer();

    const queue = new PromiseTaskQueue();

    chunks.forEach((chunk) => {
      queue.add(async () => {
        const buffer = await this.getBufferByBlob(chunk);
        spark.append(buffer);
      });
    });

    await queue.start<void>();

    return spark.end();
  };

  getBufferByBlob = async (blob:Blob):Promise<ArrayBuffer> => new Promise((resolve, reject) => {
    const fileReader = new FileReader();

    fileReader.onload = () => {
      const { result } = fileReader;

      if (result instanceof ArrayBuffer) {
        resolve(result);
        return;
      }

      reject(new Error('Unexpected file reader result'));
    };

    fileReader.onerror = () => {
      reject(new Error('文件读取错误'));
    };

    fileReader.readAsArrayBuffer(blob);
  });

  // 获取文件MD5值
  getFileMd5 = (file:File):Promise<string> => this.getFileMd5ByChunks(this.getFileChunks(file));

  private ensureError = (error:unknown):Error => {
    if (error instanceof Error) {
      return error;
    }

    return new Error(String(error));
  };
}
