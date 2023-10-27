import { ApiV3GettableResource } from 'core-app/core/apiv3/paths/apiv3-resource';
import { Observable } from 'rxjs';
import { take, tap } from 'rxjs/operators';
import { States } from 'core-app/core/states/states.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageEdocFolderCollectionResource } from 'core-app/features/hal/resources/work-package-edoc-folder-collection-resource';
import { WorkPackageEdocFolderCache } from './work-package-edoc-folder.cache';

export class ApiV3WorkPackageEdocFolderCachedSubresource extends ApiV3GettableResource<WorkPackageEdocFolderCollectionResource> {
  @InjectField() private states:States;

  public get():Observable<WorkPackageEdocFolderCollectionResource> {
    return this
      .halResourceService
      .get<WorkPackageEdocFolderCollectionResource>(this.path)
      .pipe(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument
        tap((collection) => collection.schemas && this.updateSchemas(collection.schemas)),
        tap((collection) => this.cache.updateWorkPackageList(collection.elements)),
        take(1),
      );
  }

  protected get cache():WorkPackageEdocFolderCache {
    return this.cache;
  }

  private updateSchemas(schemas:CollectionResource<SchemaResource>) {
    schemas.elements.forEach((schema) => {
      this.states.schemas.get(schema.href as string).putValue(schema);
    });
  }
}
