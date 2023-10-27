import {
  ChangeDetectionStrategy,
  Component,
  Input,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { WorkPackageEdocFilesResourceService } from 'core-app/core/state/work-package-edoc-files/work-package-edoc-files.service';

@Component({
  selector: 'op-work-package-edoc-file-list',
  templateUrl: './work-package-edoc-file-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocFileListComponent extends UntilDestroyedMixin {
  @Input() public edocFiles:WorkPackageEdocFileResource[] = [];

  constructor(
    protected readonly wpEdocFilesResourceService:WorkPackageEdocFilesResourceService,
  ) {
    super();
  }

  public removeEdocFile(edocFile:WorkPackageEdocFileResource):void {
    this.wpEdocFilesResourceService.removeAttachment(edocFile.folderId, edocFile);
  }
}
