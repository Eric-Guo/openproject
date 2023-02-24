// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Ng2StateDeclaration } from '@uirouter/angular';
import { makeSplitViewRoutes } from 'core-app/features/work-packages/routing/split-view-routes.template';
import { WorkPackageSplitViewComponent } from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view.component';
import { InAppInboxCenterComponent } from 'core-app/features/in-app-inbox/center/in-app-inbox-center.component';
import { InAppInboxCenterPageComponent } from 'core-app/features/in-app-inbox/center/in-app-inbox-center-page.component';
import { WorkPackagesBaseComponent } from 'core-app/features/work-packages/routing/wp-base/wp--base.component';
import { InAppInboxDateAlertsUpsaleComponent } from 'core-app/features/in-app-inbox/date-alerts-upsale/iai-date-alerts-upsale.component';

export interface IInboxPageQueryParameters {
  filter?:string;
  name?:string;
  projectId?:string;
}

export const IAI_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'inbox',
    parent: 'optional_project',
    url: '/inboxes?{filter:string}&{name:string}',
    data: {
      bodyClasses: 'router--work-packages-base',
    },
    redirectTo: 'inbox.center.show',
    views: {
      '!$default': { component: WorkPackagesBaseComponent },
    },
  },
  {
    url: '/date_alerts',
    name: 'inbox.date_alerts_upsale',
    component: InAppInboxDateAlertsUpsaleComponent,
  },
  {
    name: 'inbox.center',
    component: InAppInboxCenterPageComponent,
    redirectTo: 'inbox.center.show',
  },
  {
    name: 'inbox.center.show',
    data: {
      baseRoute: 'inbox.center.show',
    },
    views: {
      'content-left': { component: InAppInboxCenterComponent },
    },
  },
  ...makeSplitViewRoutes(
    'inbox.center.show',
    undefined,
    WorkPackageSplitViewComponent,
  ),
];
