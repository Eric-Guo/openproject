import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import {
  combineLatest,
  merge,
  timer,
} from 'rxjs';
import {
  filter,
  map,
  shareReplay,
  switchMap,
  throttleTime,
} from 'rxjs/operators';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IaiBellService } from 'core-app/features/in-app-inbox/bell/state/iai-bell.service';

export const opInAppInboxBellSelector = 'op-in-app-inbox-bell';
const ACTIVE_POLLING_INTERVAL = 10000;
const INACTIVE_POLLING_INTERVAL = 120000;

@Component({
  selector: opInAppInboxBellSelector,
  templateUrl: './in-app-inbox-bell.component.html',
  styleUrls: ['./in-app-inbox-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppInboxBellComponent {
  polling$ = merge(
    timer(10, ACTIVE_POLLING_INTERVAL).pipe(filter(() => this.activeWindow.isActive)),
    timer(10, INACTIVE_POLLING_INTERVAL).pipe(filter(() => !this.activeWindow.isActive)),
  )
    .pipe(
      throttleTime(ACTIVE_POLLING_INTERVAL),
      switchMap(() => this.storeService.fetchUnread()),
    );

  unreadCount$ = combineLatest([
    this.storeService.unread$,
    this.polling$,
  ]).pipe(
    map(([count]) => count),
    shareReplay(1),
  );

  unreadCountText$ = this
    .unreadCount$
    .pipe(
      map((count) => {
        if (count > 99) {
          return '99+';
        }

        if (count <= 0) {
          return '';
        }

        return count;
      }),
    );

  constructor(
    readonly storeService:IaiBellService,
    readonly apiV3Service:ApiV3Service,
    readonly activeWindow:ActiveWindowService,
    readonly pathHelper:PathHelperService,
  ) { }

  notificationsPath():string {
    return this.pathHelper.notificationsPath();
  }
}
