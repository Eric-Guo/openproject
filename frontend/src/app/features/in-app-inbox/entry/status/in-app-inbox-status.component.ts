import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnChanges,
  SimpleChanges,
} from '@angular/core';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';

@Component({
  selector: 'op-in-app-inbox-status',
  styleUrls: ['./in-app-inbox-status.component.sass'],
  templateUrl: './in-app-inbox-status.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppInboxStatusComponent implements OnChanges {
  @Input() status:StatusResource;

  highlightClass:string;

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.status) {
      const status = changes.status as { currentValue:StatusResource };
      this.highlightClass = Highlighting.backgroundClass('status', status.currentValue.id || '');
    }
  }
}
