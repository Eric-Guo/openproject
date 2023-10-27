import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { IWorkPackageEdocFileUpload } from 'core-app/core/state/work-package-edoc-files/work-package-edoc-file.model';
import { getIconForMimeType } from 'core-app/shared/components/storages/functions/storages.functions';
import { IFileIcon } from 'core-app/shared/components/storages/icons.mapping';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-work-package-edoc-upload-file-list-item]',
  templateUrl: './work-package-edoc-upload-file-list-item.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocUploadFileListItemComponent implements OnInit {
  @Input() public uploadFile:IWorkPackageEdocFileUpload;

  static imageFileExtensions:string[] = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public fileIcon:IFileIcon;

  ngOnInit():void {
    this.fileIcon = getIconForMimeType(this.uploadFile.file.type);
  }

  get fileName() {
    return this.uploadFile.file.name;
  }

  get progressColor() {
    if (this.uploadFile.status === -1) {
      return 'rgba(255, 0, 0, 0.5)';
    }
    const color1 = [31, 135, 255];
    const color2 = [62, 193, 86];
    const r = Math.round(color1[0] + ((color2[0] - color1[0]) * this.uploadFile.progress) / 100);
    const g = Math.round(color1[1] + ((color2[1] - color1[1]) * this.uploadFile.progress) / 100);
    const b = Math.round(color1[2] + ((color2[2] - color1[2]) * this.uploadFile.progress) / 100);
    return `rgba(${r}, ${g}, ${b}, 0.5)`;
  }

  get progressPercent() {
    return this.uploadFile.progress;
  }
}
