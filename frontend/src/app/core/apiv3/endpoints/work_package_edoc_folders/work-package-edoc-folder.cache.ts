import { MultiInputState } from '@openproject/reactivestates';
import { Injectable, Injector } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';

@Injectable()
export class WorkPackageEdocFolderCache extends StateCacheService<WorkPackageEdocFolderResource> {
  @InjectField() private schemaCacheService:SchemaCacheService;

  constructor(
    readonly injector:Injector,
    state:MultiInputState<WorkPackageEdocFolderResource>,
  ) {
    super(state);
  }

  updateValue(id:string, val:WorkPackageEdocFolderResource):Promise<WorkPackageEdocFolderResource> {
    return this.schemaCacheService.ensureLoaded(val).then(() => {
      this.putValue(id, val);
      return val;
    });
  }

  updateWorkPackage(folder:WorkPackageEdocFolderResource, immediate = false):Promise<WorkPackageEdocFolderResource> {
    if (immediate || isNewResource(folder)) {
      return super.updateValue(String(folder.folderId), folder);
    }
    return this.updateValue(String(folder.folderId), folder);
  }

  updateWorkPackageList(list:WorkPackageEdocFolderResource[], skipOnIdentical = true) {
    list.forEach((i) => {
      const folder = i;
      const folderId = String(folder.folderId);
      const state = this.multiState.get(folderId);

      // If the work package is new, ignore the schema
      if (isNewResource(folder)) {
        state.putValue(folder);
        return;
      }

      // Ensure the schema is loaded
      // so that no consumer needs to call schema#$load manually
      void this.schemaCacheService.ensureLoaded(folder).then(() => {
        // Check if the work package has changed
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-non-null-assertion
        if (skipOnIdentical && state.hasValue() && _.isEqual(state.value!.$source, folder.$source)) {
          debugLog('Skipping identical work package from updating');
          return;
        }

        state.putValue(folder);
      });
    });
  }
}
