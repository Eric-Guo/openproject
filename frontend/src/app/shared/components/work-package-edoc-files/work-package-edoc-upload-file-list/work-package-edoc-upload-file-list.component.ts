import {
  ChangeDetectionStrategy,
  Component,
  Input,
} from '@angular/core';
import { IWorkPackageEdocFileUpload } from 'core-app/core/state/work-package-edoc-files/work-package-edoc-file.model';

@Component({
  selector: 'op-work-package-edoc-upload-file-list',
  templateUrl: './work-package-edoc-upload-file-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocUploadFileListComponent {
  @Input() public uploadFiles:IWorkPackageEdocFileUpload[] = [];
}
