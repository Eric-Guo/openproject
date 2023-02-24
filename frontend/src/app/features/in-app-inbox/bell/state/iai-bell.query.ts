import { pairwise, filter, map } from 'rxjs/operators';
import { Query } from '@datorama/akita';
import {
  IaiBellState,
  IaiBellStore,
} from 'core-app/features/in-app-inbox/bell/state/iai-bell.store';

export class IaiBellQuery extends Query<IaiBellState> {
  unread$ = this.select('totalUnread');

  unreadCountIncreased$ = this.unread$.pipe(
    pairwise(),
    filter(([last, curr]) => curr > last),
    map(([, curr]) => curr),
  );

  constructor(protected store:IaiBellStore) {
    super(store);
  }
}
