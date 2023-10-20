import {
  ChangeDetectionStrategy,
  Component,
  Input,
} from '@angular/core';
import { UploadFile } from './work-package-edoc-upload-file-list-item.component';

@Component({
  selector: 'op-work-package-edoc-upload-file-list',
  templateUrl: './work-package-edoc-upload-file-list.component.html',
  changeDetection: ChangeDetectionStrategy.Default,
})
export class OpWorkPackageEdocUploadFileListComponent {
  @Input() public uploadFiles:UploadFile[] = [];
}
