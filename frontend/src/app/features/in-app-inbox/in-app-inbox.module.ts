import { NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { CommonModule } from '@angular/common';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { InAppInboxBellComponent } from 'core-app/features/in-app-inbox/bell/in-app-inbox-bell.component';
import { InAppInboxEntryComponent } from 'core-app/features/in-app-inbox/entry/in-app-inbox-entry.component';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { UIRouterModule } from '@uirouter/angular';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { IAI_ROUTES } from 'core-app/features/in-app-inbox/in-app-inbox.routes';
import { InAppInboxCenterComponent } from 'core-app/features/in-app-inbox/center/in-app-inbox-center.component';
import { InAppInboxCenterPageComponent } from 'core-app/features/in-app-inbox/center/in-app-inbox-center-page.component';
import { IaiMenuComponent } from 'core-app/features/in-app-inbox/center/menu/menu.component';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { DynamicModule } from 'ng-dynamic-component';
import { InAppInboxStatusComponent } from './entry/status/in-app-inbox-status.component';
import { InboxSettingsButtonComponent } from './center/toolbar/settings/inbox-settings-button.component';
import { ActivateFacetButtonComponent } from './center/toolbar/facet/activate-facet-button.component';
import { MarkAllAsReadButtonComponent } from './center/toolbar/mark-all-as-read/mark-all-as-read-button.component';
import { OpenprojectContentLoaderModule } from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { EmptyStateComponent } from './center/empty-state/empty-state.component';
import { IaiBellService } from 'core-app/features/in-app-inbox/bell/state/iai-bell.service';
import { InAppInboxActorsLineComponent } from './entry/actors-line/in-app-inbox-actors-line.component';
import { InAppInboxDateAlertComponent } from './entry/date-alert/in-app-inbox-date-alert.component';
import { InAppInboxDateAlertsUpsaleComponent } from 'core-app/features/in-app-inbox/date-alerts-upsale/iai-date-alerts-upsale.component';

@NgModule({
  declarations: [
    InAppInboxBellComponent,
    InAppInboxCenterComponent,
    InAppInboxEntryComponent,
    InAppInboxCenterPageComponent,
    InAppInboxStatusComponent,
    InboxSettingsButtonComponent,
    ActivateFacetButtonComponent,
    MarkAllAsReadButtonComponent,
    IaiMenuComponent,
    EmptyStateComponent,
    InAppInboxActorsLineComponent,
    InAppInboxDateAlertComponent,
    InAppInboxDateAlertsUpsaleComponent,
  ],
  imports: [
    OpSharedModule,
    // Routes for /backlogs
    UIRouterModule.forChild({
      states: IAI_ROUTES,
    }),
    DynamicModule,
    CommonModule,
    IconModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectWorkPackagesModule,
    OpenprojectContentLoaderModule,
    ScrollingModule,
  ],
  providers: [
    IaiBellService,
  ],
})
export class OpenProjectInAppInboxModule {
}
