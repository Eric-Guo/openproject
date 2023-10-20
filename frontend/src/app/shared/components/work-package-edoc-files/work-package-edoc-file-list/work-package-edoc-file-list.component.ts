import {
  ChangeDetectionStrategy,
  Component,
  Input,
} from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { catchError } from 'rxjs';

@Component({
  selector: 'op-work-package-edoc-file-list',
  templateUrl: './work-package-edoc-file-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocFileListComponent extends UntilDestroyedMixin {
  @Input() public edocFiles:WorkPackageEdocFileResource[] = [];

  @Input() public refreshList:() => void;

  constructor(private readonly http:HttpClient) {
    super();
  }

  public removeEdocFile(edocFile:WorkPackageEdocFileResource):void {
    const url = edocFile.remove?.href;
    if (!url) return;
    this.http.delete(url, {
      headers: {
        'Content-Type': 'application/json',
      },
    }).pipe(
      catchError((error) => {
        throw error;
      }),
    ).subscribe(() => {
      this.refreshList?.();
    });
  }
}
