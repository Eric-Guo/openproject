import { Store, StoreConfig } from '@datorama/akita';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export interface IaiMenuGroupingData {
  value:string;
  count:number;
  projectHasParent?:boolean;
  _links:{
    valueLink:{
      href:string;
    }[];
  };
}

export interface BaseMenuItemData {
  value:string;
  count:number;
}

export interface IaiMenuState {
  notificationsByProject:IaiMenuGroupingData[],
  notificationsByReason:IaiMenuGroupingData[],
  projectsFilter:ApiV3ListParameters,
}

export const IAI_MENU_PROJECT_FILTERS:ApiV3ListParameters = {
  pageSize: 100,
  groupBy: 'project',
  filters: [['read_ian', '=', false]],
};

export const IAI_MENU_REASON_FILTERS:ApiV3ListParameters = {
  pageSize: 100,
  groupBy: 'reason',
  filters: [['read_ian', '=', false]],
};

export function createInitialState():IaiMenuState {
  return {
    notificationsByProject: [],
    notificationsByReason: [],
    projectsFilter: {},
  };
}

@StoreConfig({ name: 'ian-menu' })
export class IaiMenuStore extends Store<IaiMenuState> {
  constructor() {
    super(createInitialState());
  }
}
