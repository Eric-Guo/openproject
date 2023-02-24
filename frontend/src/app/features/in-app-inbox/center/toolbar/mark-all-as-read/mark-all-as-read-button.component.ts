import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IaiCenterService } from 'core-app/features/in-app-inbox/center/state/iai-center.service';

@Component({
  selector: 'op-mark-all-as-read-button',
  templateUrl: './mark-all-as-read-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MarkAllAsReadButtonComponent {
  text = {
    mark_all_read: this.I18n.t('js.notifications.center.mark_all_read'),
  };

  constructor(
    private I18n:I18nService,
    private storeService:IaiCenterService,
  ) {
  }

  markAllRead():void {
    this.storeService.markAllAsRead();
  }
}
