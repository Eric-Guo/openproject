import { Injector } from '@angular/core';
import { Observable } from 'rxjs';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageEdocFilesResourceService } from 'core-app/core/state/work-package-edoc-files/work-package-edoc-files.service';

export function workPackageEdocFilesCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const attachmentService = injector.get(WorkPackageEdocFilesResourceService);
  return new Observable<number>((ob) => {
    attachmentService.subscribeFiles(Number(workPackage.id), (list) => ob.next(list.length));
  });
}
