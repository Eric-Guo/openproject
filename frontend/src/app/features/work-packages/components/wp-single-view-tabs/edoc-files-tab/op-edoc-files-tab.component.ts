import { ChangeDetectionStrategy, Component } from '@angular/core';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-edoc-files-tab',
  templateUrl: './op-edoc-files-tab.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageEdocFilesTabComponent {
  workPackage:WorkPackageResource;

  text = {
    attachments: {
      label: this.i18n.t('js.label_attachments'),
    },
  };

  constructor(
    private readonly i18n:I18nService,
  ) { }
}
