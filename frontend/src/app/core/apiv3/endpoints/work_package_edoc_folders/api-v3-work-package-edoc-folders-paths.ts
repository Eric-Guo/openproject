import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Collection } from 'core-app/core/apiv3/cache/cachable-apiv3-collection';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { ApiV3GettableResource } from 'core-app/core/apiv3/paths/apiv3-resource';
import {
  ApiV3FilterBuilder,
  ApiV3FilterValueType,
  ApiV3Filter,
} from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ApiV3WorkPackageEdocFolderPaths } from './api-v3-work-package-edoc-folder-paths';
import { WorkPackageEdocFolderResource } from 'core-app/features/hal/resources/work-package-edoc-folder-resource';
import { WorkPackageEdocFolderCache } from './work-package-edoc-folder.cache';
import { ApiV3WorkPackageEdocFolderCachedSubresource } from './api-v3-work-package-edoc-folder-cached-subresource';
import { WorkPackageEdocFolderCollectionResource } from 'core-app/features/hal/resources/work-package-edoc-folder-collection-resource';

export class ApiV3WorkPackageEdocFoldersPaths extends ApiV3Collection<WorkPackageEdocFolderResource, ApiV3WorkPackageEdocFolderPaths, WorkPackageEdocFolderCache> {
  // Base path
  public readonly path:string;

  constructor(
    readonly apiRoot:ApiV3Service,
    protected basePath:string,
  ) {
    super(apiRoot, basePath, 'work_package_edoc_folders', ApiV3WorkPackageEdocFolderPaths);
  }

  /**
   *
   * Load a collection of work packages and put them all into cache
   *
   * @param ids
   */
  public requireAll(ids:string[]):Promise<unknown> {
    if (ids.length === 0) {
      return Promise.resolve();
    }

    return new Promise<undefined>((resolve, reject) => {
      this
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
        .loadCollectionsFor(_.uniq(ids))
        .then((pagedResults:WorkPackageEdocFolderCollectionResource[]) => {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
          _.each(pagedResults, (results) => {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            if (results.schemas) {
              // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
              _.each(results.schemas.elements, (schema:SchemaResource) => {
                this.states.schemas.get(schema.href as string).putValue(schema);
              });
            }

            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            if (results.elements) {
              // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
              this.cache.updateWorkPackageList(results.elements);
            }
          });

          resolve(undefined);
        }, reject);
    });
  }

  filtered<R = ApiV3GettableResource<WorkPackageEdocFolderCollectionResource>>(filters:ApiV3FilterBuilder, params:{ [p:string]:string } = {}):R {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-explicit-any
    return super.filtered(filters, params, ApiV3WorkPackageEdocFolderCachedSubresource) as any;
  }

  /**
   * Shortcut to filter work packages by subject or ID
   * @param term
   * @param idOnly
   * @param additionalParams Additional set of params to the API
   */
  public filterByTypeaheadOrId(term:string, idOnly = false, additionalParams:{ [key:string]:string } = {}):ApiV3WorkPackageEdocFolderCachedSubresource {
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

    if (idOnly) {
      filters.add('id', '=', [term]);
    } else {
      filters.add('typeahead', '**', [term]);
    }

    const params = {
      sortBy: '[["updatedAt","desc"]]',
      offset: '1',
      pageSize: '10',
      ...additionalParams,
    };

    return this.filtered(filters, params);
  }

  /**
   * Returns work packages within the ids array to be updated since <timestamp>
   * @param ids work package IDs to filter for
   * @param timestamp The timestamp to clip at
   */
  public filterUpdatedSince(ids:(string|null)[], timestamp:ApiV3FilterValueType):ApiV3WorkPackageEdocFolderCachedSubresource {
    const filters = new ApiV3FilterBuilder()
      .add('id', '=', (ids.filter((n) => n) as string[]))
      .add('updatedAt', '<>d', [timestamp, '']);

    const params = {
      offset: '1',
      pageSize: '10',
    };

    return this.filtered(filters, params);
  }

  /**
   * Loads the work packages collection for the given work package IDs.
   * Returns a WP Collection with schemas and results embedded.
   *
   * @param ids
   * @return {WorkPackageEdocFolderCollectionResource[]}
   */
  protected loadCollectionsFor(ids:string[]):Promise<WorkPackageEdocFolderCollectionResource[]> {
    return this
      .halResourceService
      .getAllPaginated(
        this.path,
        { filters: ApiV3Filter('id', '=', ids).toJson() },
      )
      .toPromise() as Promise<WorkPackageEdocFolderCollectionResource[]>;
  }

  protected createCache():WorkPackageEdocFolderCache {
    return new WorkPackageEdocFolderCache(this.injector, this.states.workPackageEdocFolders);
  }
}
