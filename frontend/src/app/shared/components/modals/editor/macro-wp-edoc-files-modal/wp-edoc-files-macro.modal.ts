import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageEdocFilesResourceService } from 'core-app/core/state/work-package-edoc-files/work-package-edoc-files.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';

@Component({
  templateUrl: './wp-edoc-files-macro.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpEdocFilesMacroModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  public showClose = true;

  public changed = false;

  public resource:HalResource;

  public fileLinks:{ name:string; href:string; }[] = [];

  public text:Record<string, string> = {
    title: this.I18n.t('js.work_packages.tabs.files'),
    button_save: this.I18n.t('js.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  constructor(
    readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    protected currentProject:CurrentProjectService,
    protected apiV3Service:ApiV3Service,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    protected readonly wpEdocFilesResourceService:WorkPackageEdocFilesResourceService,
    protected readonly toastService:ToastService,
    private readonly halResourceService:HalResourceService,
  ) {
    super(locals, cdRef, elementRef);
    this.resource = this.halResourceService.createHalResource({ id: this.locals.wpId as string, _type: 'WorkPackage' });
  }

  public applyAndClose(evt:Event):void {
    this.changed = true;
    this.closeMe(evt);
  }

  public handleCheckedChange = (list:WorkPackageEdocFileResource[]) => {
    this.fileLinks = list.map((file) => ({ name: file.name, href: file.publishPreviewUrl }));
  };
}
