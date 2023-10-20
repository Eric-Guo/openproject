import { Injector } from '@angular/core';
import { combineLatest, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';

export function workPackageEdocFilesCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const attachmentService = injector.get(AttachmentsResourceService);
  const fileLinkService = injector.get(FileLinksResourceService);

  return combineLatest(
    [
      attachmentService.collection(workPackage.$links.attachments.href || ''),
      fileLinkService.collection(workPackage.$links.fileLinks?.href || ''),
    ],
  ).pipe(
    map(([a, f]) => a.length + f.length),
  );
}
