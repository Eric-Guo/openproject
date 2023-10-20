import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { getIconForMimeType } from 'core-app/shared/components/storages/functions/storages.functions';
import { IFileIcon } from 'core-app/shared/components/storages/icons.mapping';

export type UploadFile = {
  progress:number;
  file:File;
  status:0 | 1 | -1;
};

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-work-package-edoc-upload-file-list-item]',
  templateUrl: './work-package-edoc-upload-file-list-item.component.html',
  changeDetection: ChangeDetectionStrategy.Default,
})
export class OpWorkPackageEdocUploadFileListItemComponent implements OnInit {
  @Input() public uploadFile:UploadFile;

  static imageFileExtensions:string[] = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public fileIcon:IFileIcon;

  ngOnInit():void {
    this.fileIcon = getIconForMimeType(this.uploadFile.file.type);
  }

  get fileName() {
    return this.uploadFile.file.name;
  }

  get progressColor() {
    if (this.uploadFile.status === 1) {
      return 'rgba(62, 193, 86, 0.5)';
    }
    if (this.uploadFile.status === -1) {
      return 'rgba(255, 0, 0, 0.5)';
    }
    return 'rgba(31, 135, 255, 0.5)';
  }

  get progressPercent() {
    return this.uploadFile.progress;
  }
}
