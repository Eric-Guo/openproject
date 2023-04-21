import { Store, StoreConfig } from '@datorama/akita';
import { CollectionResponse } from 'core-app/core/state/resource-store';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IInboxPageQueryParameters } from 'core-app/features/in-app-inbox/in-app-inbox.routes';

export type InAppInboxFacet = 'unread'|'all';

export interface IaiCenterState {
  params:{
    page:number;
    pageSize:number;
  };
  activeFacet:InAppInboxFacet;
  filters:IInboxPageQueryParameters;

  activeCollection:CollectionResponse;

  /** Number of elements not showing after max values loaded */
  notLoaded:number;
}

export const IAI_FACET_FILTERS:Record<InAppInboxFacet, ApiV3ListFilter[]> = {
  unread: [['readIAN', '=', false]],
  all: [],
};

export function createInitialState():IaiCenterState {
  return {
    params: {
      pageSize: NOTIFICATIONS_MAX_SIZE,
      page: 1,
    },
    filters: {},
    activeCollection: { ids: [] },
    activeFacet: 'unread',
    notLoaded: 0,
  };
}

@StoreConfig({ name: 'iai-center' })
export class IaiCenterStore extends Store<IaiCenterState> {
  constructor() {
    super(createInitialState());
  }
}
