import { Injectable, Injector } from '@angular/core';
import {
  HttpClient,
  HttpErrorResponse,
  HttpHeaders,
} from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  catchError,
} from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageEdocFileUploadService } from 'core-app/core/upload/work-package-edoc-file-upload.service';
import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';
import { IWorkPackageEdocFileUpload } from './work-package-edoc-file.model';
import { PromiseTaskQueue } from 'core-app/shared/helpers/promise-task-queue';
import { SimpleStore, StoreSubscriber } from 'core-app/shared/helpers/simple-store';

type EventName = 'uploadstart' | 'uploadfinish' | 'uploaderror';
type EventListener = () => void;

@Injectable()
export class WorkPackageEdocFilesResourceService {
  protected folders = new Map<number, WorkPackageEdocFolderResource>();

  protected fileStores = new Map<number, SimpleStore<WorkPackageEdocFileResource>>();

  protected uploadStores = new Map<number, SimpleStore<IWorkPackageEdocFileUpload>>();

  private listeners = new Map<EventName, EventListener[]>();

  constructor(
    readonly injector:Injector,
    readonly http:HttpClient,
    readonly apiV3Service:ApiV3Service,
    readonly toastService:ToastService,
    readonly I18n:I18nService,
    readonly uploadService:WorkPackageEdocFileUploadService,
    readonly configurationService:ConfigurationService,
  ) {}

  private fetchFolder = (wpId:number) => this.apiV3Service.work_packages.id(wpId).edoc_folder.get();

  public getFolder = (wpId:number) => new Observable<WorkPackageEdocFolderResource>((ob) => {
    const folder = this.folders.get(wpId);
    if (folder) {
      ob.next(folder);
      ob.complete();
    } else {
      this.fetchFolder(wpId).subscribe((res) => {
        this.folders.set(wpId, res);
        ob.next(res);
        ob.complete();
        this.fetchCollection(wpId);
      });
    }
  });

  private getFileStore(wpId:number) {
    const store = this.fileStores.get(wpId);
    if (store) return store;
    const newStore = new SimpleStore<WorkPackageEdocFileResource>();
    this.fileStores.set(wpId, newStore);
    return newStore;
  }

  private getUploadStore(wpId:number) {
    const store = this.uploadStores.get(wpId);
    if (store) return store;
    const newStore = new SimpleStore<IWorkPackageEdocFileUpload>();
    this.uploadStores.set(wpId, newStore);
    return newStore;
  }

  private getListeners = (eventName:EventName) => {
    const listeners = this.listeners.get(eventName);
    if (listeners) return listeners;
    const newListeners:EventListener[] = [];
    this.listeners.set(eventName, newListeners);
    return newListeners;
  };

  public addEventListener(eventName:EventName, listener:EventListener) {
    const listeners = this.getListeners(eventName);
    listeners.push(listener);
  }

  public removeEventListener(eventName:EventName, listener:EventListener) {
    const listeners = this.getListeners(eventName);
    const index = listeners.indexOf(listener);
    if (index !== -1) {
      listeners.splice(index, 1);
    }
  }

  public subscribeFiles(wpId:number, subscriber:StoreSubscriber<WorkPackageEdocFileResource>) {
    const store = this.getFileStore(wpId);
    store.subscribe(subscriber);
  }

  public subscribeUploads(wpId:number, subscriber:StoreSubscriber<IWorkPackageEdocFileUpload>) {
    const store = this.getUploadStore(wpId);
    store.subscribe(subscriber);
  }

  public unsubscribeFiles(wpId:number, subscriber:StoreSubscriber<WorkPackageEdocFileResource>) {
    const store = this.getFileStore(wpId);
    store.unsubscribe(subscriber);
  }

  public unsubscribeUploads(wpId:number, subscriber:StoreSubscriber<IWorkPackageEdocFileUpload>) {
    const store = this.getUploadStore(wpId);
    store.unsubscribe(subscriber);
  }

  public fetchCollection(wpId:number) {
    if (!wpId) return;
    this.apiV3Service.work_packages.id(wpId).edoc_files.get().subscribe((res) => {
      const store = this.getFileStore(wpId);
      store.setAll(res.elements);
    });
  }

  public removeAttachment(wpId:number, resource:WorkPackageEdocFileResource) {
    const headers = new HttpHeaders({ 'Content-Type': 'application/json' });

    if (!resource.remove || !resource.remove.href) throw new Error('删除url不存在');

    this.http
      .delete<void>(resource.remove.href, { withCredentials: true, headers })
      .pipe(
        catchError((error:HttpErrorResponse) => {
          this.toastService.addError(error);
          throw new Error(error.message);
        }),
      ).subscribe(() => {
        this.fetchCollection(wpId);
      });
  }

  public attachFiles(wpId:number, files:File[]) {
    this.getFolder(wpId).subscribe((folder) => {
      this.uploadAttachments(wpId, folder, files);
    });
  }

  public uploadAttachments(wpId:number, folder:WorkPackageEdocFolderResource, files:File[]) {
    const queue = new PromiseTaskQueue();

    const uploadFiles:IWorkPackageEdocFileUpload[] = files.map((file) => (
      {
        file,
        progress: 0,
        status: 0,
      }
    ));

    const store = this.getUploadStore(wpId);

    queue.onStart(() => {
      store.setAll(uploadFiles);
      const listeners = this.getListeners('uploadstart');
      listeners.forEach((listener) => listener());
    });

    queue.onError(() => {
      const listeners = this.getListeners('uploaderror');
      listeners.forEach((listener) => listener());
    });

    queue.onFinish(() => {
      store.clear();
      this.fetchCollection(wpId);
      const listeners = this.getListeners('uploadfinish');
      listeners.forEach((listener) => listener());
    });

    files.forEach((file, index) => {
      queue.add(async () => {
        try {
          void await this.uploadService.upload(
            folder,
            file,
            {
              onStart: () => {
                store.update(index, (item) => {
                  item.status = 1;
                  return { ...item };
                });
              },
              onComplete: () => {
                store.update(index, (item) => {
                  item.status = 2;
                  item.progress = 100;
                  return { ...item };
                });
              },
              onProgress: (info) => {
                store.update(index, (item) => {
                  item.progress = Math.round((100 * info.current) / info.total);
                  return { ...item };
                });
              },
              onError: () => {
                store.update(index, (item) => {
                  item.status = -1;
                  return { ...item };
                });
              },
            },
          );
        } catch (e) {
          console.error(e);
          store.update(index, (item) => {
            item.status = -1;
            return { ...item };
          });
        }
      });
    });

    void queue.start();
  }
}
