import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';
import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';
import { ApiV3GettableResourceCollection } from '../../paths/apiv3-resource';

export class ApiV3WorkPackageEdocFolderPaths extends ApiV3Resource<WorkPackageEdocFolderResource> {
  protected createCache():StateCacheService<WorkPackageEdocFolderResource> {
    return this.cache;
  }

  // /api/v3/work_package_edoc_folders/(:workPackageId)/files
  public readonly files = this.subResource<ApiV3GettableResourceCollection<WorkPackageEdocFileResource>>('files');
}
