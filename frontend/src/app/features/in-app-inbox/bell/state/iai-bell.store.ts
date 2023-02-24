import {
  Store,
  StoreConfig,
} from '@datorama/akita';

export interface IaiBellState {
  totalUnread:number;
}

export function createInitialState():IaiBellState {
  return {
    totalUnread: 0,
  };
}

@StoreConfig({ name: 'iai-bell' })
export class IaiBellStore extends Store<IaiBellState> {
  constructor() {
    super(createInitialState());
  }
}
