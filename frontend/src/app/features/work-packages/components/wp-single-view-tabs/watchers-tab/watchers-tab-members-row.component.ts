import {
  Component, Input,
} from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { MembershipResource } from 'core-app/features/hal/resources/membership-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

// eslint-disable-next-line change-detection-strategy/on-push
@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-watchers-tab-members-row',
  templateUrl: './watchers-tab-members-row.component.html',
})
export class WorkPackageWatchersTabMembersRowComponent {
  @Input() member:MembershipResource;

  @Input() checked:string[];

  @Input() onChange:(checked:boolean, member:MembershipResource) => void;

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly i18n:I18nService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly toastService:ToastService,
  ) {}

  get principal() {
    return this.member.principal;
  }

  get memberRoles() {
    return this.member.roles.map((item) => item.name).join(',');
  }

  get email() {
    return this.member.email;
  }

  get mailTo() {
    if (!this.email) return '#';
    return `mailto:${this.email}`;
  }

  get status() {
    return this.member.status;
  }

  get statusName() {
    return this.member.statusName;
  }

  get isInvited() {
    return this.status === 'invited';
  }

  get company() {
    return this.member.profile?.company;
  }

  get department() {
    return this.member.profile?.department;
  }

  get position() {
    return this.member.profile?.position;
  }

  get major() {
    return this.member.profile?.major;
  }

  get mobile() {
    return this.member.profile?.mobile;
  }

  get remark() {
    return this.member.profile?.remark;
  }
}
