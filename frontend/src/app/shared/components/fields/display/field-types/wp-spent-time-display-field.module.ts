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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { withTooltip } from 'core-app/shared/helpers/tooltip-helper';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkDisplayField } from 'core-app/shared/components/fields/display/field-types/work-display-field.module';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';

type WorkPackageWithSpentTimeLink = WorkPackageResource&{
  showSpentTime?:CallableHalLink;
};

export class WorkPackageSpentTimeDisplayField extends WorkDisplayField {
  public text = {
    linkTitle: this.I18n.t('js.work_packages.message_view_spent_time'),
    logTime: this.I18n.t('js.button_log_time'),
  };

  public render(element:HTMLElement, displayText:string):void {
    if (!this.value) {
      return;
    }

    const link = document.createElement('a');
    link.textContent = displayText;

    if (displayText === this.placeholder) {
      link.setAttribute(
        'class',
        'time-logging--value time-logging--value_empty',
      );
    } else {
      link.setAttribute('class', 'time-logging--value');
    }

    const showSpentTime = (this.resource as WorkPackageWithSpentTimeLink).showSpentTime;
    if (showSpentTime?.href) {
      link.href = showSpentTime.href;
    }

    element.innerHTML = '';
    element.appendChild(withTooltip(link, this.text.linkTitle, 'description'));

    this.appendTimelogLink(element);
  }

  private appendTimelogLink(element:HTMLElement) {
    if (this.resource.logTime) {
      const timelogElement = document.createElement('a');
      timelogElement.setAttribute('class', 'icon icon-time');
      timelogElement.setAttribute('href', 'https://ith-workspace.thape.com.cn/workbenchApi/auth/sso-login?redirect_uri=https%3A%2F%2Fith-workspace.thape.com.cn%2Fith-worktime%2Fday');
      timelogElement.setAttribute('target', 'th_keyin');

      element.appendChild(withTooltip(timelogElement, this.text.logTime, 'label'));
    }
  }
}
