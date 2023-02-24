import { ChangeDetectionStrategy, Component } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IaiCenterService } from 'core-app/features/in-app-inbox/center/state/iai-center.service';
import {
  IAI_FACET_FILTERS,
  InAppInboxFacet,
} from 'core-app/features/in-app-inbox/center/state/iai-center.store';

@Component({
  selector: 'op-activate-facet',
  templateUrl: './activate-facet-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ActivateFacetButtonComponent {
  text = {
    facets: {
      unread: this.I18n.t('js.notifications.facets.unread'),
      all: this.I18n.t('js.notifications.facets.all'),
    },
    facet_titles: {
      unread: this.I18n.t('js.notifications.facets.unread_title'),
      all: this.I18n.t('js.notifications.facets.all_title'),
    },
  };

  availableFacets = Object.keys(IAI_FACET_FILTERS);

  activeFacet$ = this.storeService.activeFacet$;

  constructor(
    private I18n:I18nService,
    private storeService:IaiCenterService,
  ) {
  }

  activateFacet(facet:InAppInboxFacet):void {
    this.storeService.setFacet(facet);
  }
}
