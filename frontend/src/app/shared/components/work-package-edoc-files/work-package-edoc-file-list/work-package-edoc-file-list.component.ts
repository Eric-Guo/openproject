import {
  ChangeDetectionStrategy,
  Component,
  Input,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { WorkPackageEdocFilesResourceService } from 'core-app/core/state/work-package-edoc-files/work-package-edoc-files.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Component({
  selector: 'op-work-package-edoc-file-list',
  templateUrl: './work-package-edoc-file-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocFileListComponent extends UntilDestroyedMixin {
  @Input() public resource:HalResource;

  @Input() public edocFiles:WorkPackageEdocFileResource[] = [];

  @Input() public showCheckbox = false;

  @Input() public hideRemoveButton = false;

  @Input() public onCheckedChange?:(edocFile:WorkPackageEdocFileResource, checked:boolean) => void;

  constructor(
    protected readonly wpEdocFilesResourceService:WorkPackageEdocFilesResourceService,
  ) {
    super();
  }

  public handleCheckedChange(edocFile:WorkPackageEdocFileResource, checked:boolean):void {
    this.onCheckedChange?.(edocFile, checked);
  }

  public removeEdocFile(edocFile:WorkPackageEdocFileResource):void {
    if (!this.resource.id) return;
    this.wpEdocFilesResourceService.removeAttachment(Number(this.resource.id), edocFile);
    this.onCheckedChange?.(edocFile, false);
  }
}
