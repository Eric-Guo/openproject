import { AfterViewInit, ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageWatchersService } from './wp-watchers.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Component({
  templateUrl: './watchers-tab-button-group.html',
  styleUrls: ['./watchers-tab-button-group.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-watchers-tab-button-group',
})
export class WorkPackageWatchersTabButtonGroupComponent implements AfterViewInit {
  @Input() addWatchers:(users:any[]) => void;

  @Input() workPackage:WorkPackageResource;

  @Input() loading:boolean;

  private parentWatching:any[] = [];

  constructor(
    readonly wpWatchersService:WorkPackageWatchersService,
    readonly notificationService:WorkPackageNotificationService,
    readonly apiV3Service:ApiV3Service,
  ) {}

  ngAfterViewInit():void {
    this.loadParentWatchers();
  }

  get allowSyncParentWatchers() {
    return !!this.workPackage && !!this.workPackage.addWatcher && !!this.workPackage.parent;
  }

  public loadParentWatchers() {
    if (!this.allowSyncParentWatchers) {
      return;
    }

    this.apiV3Service.work_packages.id(this.workPackage.parent!.id!)
      .requireAndStream()
      .subscribe((wp:WorkPackageResource) => {
        this.wpWatchersService.require(wp)
          .then((watchers:HalResource[]) => {
            this.parentWatching = watchers;
          })
          .catch((error:any) => {
            this.notificationService.showError(error, wp);
          });
      });
  }

  public syncParentWatchers() {
    if (!this.allowSyncParentWatchers) {
      return;
    }
    this.addWatchers(this.parentWatching);
  }
}
