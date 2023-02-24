import { Injectable } from '@angular/core';
import { IaiBellStore } from './iai-bell.store';
import {
  InAppNotificationsResourceService,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { IAI_FACET_FILTERS } from 'core-app/features/in-app-inbox/center/state/iai-center.store';
import {
  map,
  tap,
  skip,
  catchError,
} from 'rxjs/operators';
import {
  EMPTY,
  Observable,
} from 'rxjs';
import { IaiBellQuery } from 'core-app/features/in-app-inbox/bell/state/iai-bell.query';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import {
  notificationsMarkedRead,
  notificationCountIncreased,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';

/**
 * The BellService is injected into root here (and the store is thus made global),
 * because we are dependent in many places on the information about how many notifications there are in total.
 * Instead of repeating these requests, we prefer to use the global store for now.
 */
@Injectable({ providedIn: 'root' })
@EffectHandler
export class IaiBellService {
  readonly id = 'iai-bell';

  readonly store = new IaiBellStore();

  readonly query = new IaiBellQuery(this.store);

  unread$ = this.query.unread$;

  constructor(
    readonly actions$:ActionsService,
    readonly resourceService:InAppNotificationsResourceService,
  ) {
    this.query.unreadCountIncreased$.pipe(skip(1)).subscribe((count) => {
      this.actions$.dispatch(notificationCountIncreased({ origin: this.id, count }));
    });
  }

  fetchUnread():Observable<number> {
    return this
      .resourceService
      .fetchCollection(
        { filters: IAI_FACET_FILTERS.unread, pageSize: 0 },
        { handleErrors: false },
      )
      .pipe(
        map((result) => result.total),
        tap(
          (count) => {
            this.store.update({ totalUnread: count });
          },
          (error) => {
            console.error('Failed to load notifications: %O', error);
            this.store.update({ totalUnread: -1 });
          },
        ),
        catchError(() => EMPTY),
      );
  }

  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    this.store.update(({ totalUnread }) => ({ totalUnread: totalUnread - action.notifications.length }));
  }
}
