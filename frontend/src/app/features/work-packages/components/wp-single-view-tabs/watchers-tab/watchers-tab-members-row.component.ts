//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
  standalone: false,
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
