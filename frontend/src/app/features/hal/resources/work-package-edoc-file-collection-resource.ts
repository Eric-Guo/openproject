import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { WorkPackageEdocFileResource } from './work-package-edoc-file-resource';

export class WorkPackageEdocFileCollectionResource extends CollectionResource {
  public $initialize(source:any) {
    super.$initialize(source);

    this.elements = this.elements || [];
  }
}

export interface WorkPackageEdocFileCollectionResource {
  elements:WorkPackageEdocFileResource[];
}
