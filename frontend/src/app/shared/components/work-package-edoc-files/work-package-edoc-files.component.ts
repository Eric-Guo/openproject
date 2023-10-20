import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  Input,
  OnDestroy,
  OnInit,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';

import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';
import { WorkPackageEdocFileUploadService } from 'core-app/core/upload/work-package-edoc-file-upload.service';
import { UploadFile } from './work-package-edoc-upload-file-list/work-package-edoc-upload-file-list-item.component';
import { PromiseTaskQueue } from 'core-app/shared/helpers/promise-task-queue';

function containsFiles(dataTransfer:DataTransfer):boolean {
  return dataTransfer.types.indexOf('Files') >= 0;
}

export const edocFilesSelector = 'op-work-package-edoc-files';

@Component({
  selector: edocFilesSelector,
  templateUrl: './work-package-edoc-files.component.html',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocFilesComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @HostBinding('attr.data-qa-selector') public qaSelector = 'op-work-package-edoc-files';

  @HostBinding('id.attachments_fields') public hostId = true;

  @HostBinding('class.op-file-section') public className = true;

  @Input() public resource:HalResource;

  public edocFolder:WorkPackageEdocFolderResource;

  public edocFiles:WorkPackageEdocFileResource[] = [];

  public draggingOverDropZone = false;

  public dragging = 0;

  public uploadFileList:UploadFile[] = [];

  @ViewChild('hiddenFileInput') public filePicker:ElementRef<HTMLInputElement>;

  public text = {
    attachments: this.I18n.t('js.label_attachments'),
    uploadLabel: this.I18n.t('js.label_add_attachments'),
    dropFiles: this.I18n.t('js.label_drop_files'),
    dropClickFiles: this.I18n.t('js.label_drop_or_click_files'),
    foldersWarning: this.I18n.t('js.label_drop_folders_hint'),
  };

  private onGlobalDragLeave:(_event:DragEvent) => void = (_event) => {
    this.dragging = Math.max(this.dragging - 1, 0);
    this.cdRef.detectChanges();
  };

  private onGlobalDragEnd:(_event:DragEvent) => void = (_event) => {
    this.dragging = 0;
    this.cdRef.detectChanges();
  };

  private onGlobalDragEnter:(_event:DragEvent) => void = (_event) => {
    this.dragging += 1;
    this.cdRef.detectChanges();
  };

  constructor(
    public elementRef:ElementRef,
    protected readonly I18n:I18nService,
    protected readonly states:States,
    protected readonly toastService:ToastService,
    private readonly uploadService:WorkPackageEdocFileUploadService,
    private readonly apiV3Service:ApiV3Service,
    protected readonly halResourceService:HalResourceService,
    protected readonly timezoneService:TimezoneService,
    protected readonly cdRef:ChangeDetectorRef,
  ) {
    super();

    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    this.getEdocFolder();
    this.getEdocFiles();

    document.body.addEventListener('dragenter', this.onGlobalDragEnter);
    document.body.addEventListener('dragleave', this.onGlobalDragLeave);
    document.body.addEventListener('dragend', this.onGlobalDragEnd);
    document.body.addEventListener('drop', this.onGlobalDragEnd);
  }

  ngOnDestroy():void {
    document.body.removeEventListener('dragenter', this.onGlobalDragEnter);
    document.body.removeEventListener('dragleave', this.onGlobalDragLeave);
    document.body.removeEventListener('dragend', this.onGlobalDragEnd);
    document.body.removeEventListener('drop', this.onGlobalDragEnd);
  }

  getEdocFolder = () => {
    if (!this.resource.id) return;
    this.apiV3Service.work_packages.id(this.resource.id).edoc_folder.get().subscribe((res) => {
      if (!res) return;
      this.edocFolder = res;
      this.cdRef.detectChanges();
      if (!res.publishUrl) {
        setTimeout(this.getEdocFolder, 5000);
      }
    });
  };

  getEdocFiles = () => {
    if (!this.resource.id) return;
    this.apiV3Service.work_packages.id(this.resource.id).edoc_files.get().subscribe((res) => {
      this.edocFiles = res.elements;
      this.cdRef.detectChanges();
    });
  };

  get allowUpload() {
    return !!this.edocFolder && !!this.edocFolder.create_file && this.uploadFileList.length === 0;
  }

  get publishUrl() {
    return this.edocFolder?.publishUrl;
  }

  goToFolder() {
    if (!this.publishUrl) return;
    window.open(this.publishUrl, '_blank', 'noreferrer');
  }

  public triggerFileInput():void {
    this.filePicker.nativeElement.click();
  }

  public onFilePickerChanged():void {
    const fileList = this.filePicker.nativeElement.files;
    if (fileList === null) return;
    const files = Array.from(fileList);
    // reset file input, so that selecting the same file again triggers a change
    this.filePicker.nativeElement.value = '';
    this.uploadFiles(files);
  }

  public onDropFiles(event:DragEvent):void {
    if (event.dataTransfer === null) return;

    // eslint-disable-next-line no-param-reassign
    event.dataTransfer.dropEffect = 'copy';

    this.uploadFiles(Array.from(event.dataTransfer.files));
    this.draggingOverDropZone = false;
    this.dragging = 0;
  }

  public onDragOver(event:DragEvent):void {
    if (event.dataTransfer !== null && containsFiles(event.dataTransfer)) {
      // eslint-disable-next-line no-param-reassign
      event.dataTransfer.dropEffect = 'copy';
      this.draggingOverDropZone = true;
    }
  }

  public onDragLeave(_event:DragEvent):void {
    this.draggingOverDropZone = false;
  }

  protected uploadFiles(files:File[]):void {
    let filesWithoutFolders = files || [];
    const countBefore = files.length;
    filesWithoutFolders = this.filterFolders(filesWithoutFolders);

    if (filesWithoutFolders.length === 0) {
      // If we filtered all files as directories, show a notice
      if (countBefore > 0) {
        this.toastService.addNotice(this.text.foldersWarning);
      }

      return;
    }

    this.uploadFileList = filesWithoutFolders.map((file) => ({
      file,
      progress: 0,
      status: 0,
    }));

    this.cdRef.detectChanges();

    const queue = new PromiseTaskQueue();

    queue.onFinish(() => {
      setTimeout(() => {
        this.uploadFileList = [];
        this.getEdocFiles();
      }, 500);
    });

    this.uploadFileList.forEach((uploadFile) => {
      queue.add(async () => {
        try {
          void await this.uploadService.upload(
            this.edocFolder,
            uploadFile.file,
            {
              onComplete: () => {
                uploadFile.status = 1;
                uploadFile.progress = 100;
                this.cdRef.detectChanges();
              },
              onProgress: (info) => {
                uploadFile.progress = Math.round((100 * info.current) / info.total);
                this.cdRef.detectChanges();
              },
              onError: () => {
                uploadFile.status = -1;
                this.cdRef.detectChanges();
              },
            },
          );
        } catch (e) {
          console.error(e);
          uploadFile.status = -1;
          this.cdRef.detectChanges();
        }
      });
    });

    void queue.start();
  }

  /**
   * We try to detect folders by checking for either empty types
   * or empty file sizes.
   * @param files
   */
  protected filterFolders(files:File[]):File[] {
    return files.filter((file) => {
      // Folders never have a mime type
      if (file.type !== '') {
        return true;
      }

      // Files however MAY have no mime type as well
      // so fall back to checking zero or 4096 bytes
      if (file.size === 0 || file.size === 4096) {
        console.warn(`Skipping file because of file size (${file.size}) %O`, file);
        return false;
      }

      return true;
    });
  }
}
