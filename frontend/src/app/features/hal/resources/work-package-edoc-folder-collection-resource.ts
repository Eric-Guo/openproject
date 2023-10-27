import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { WorkPackageEdocFolderResource } from './work-package-edoc-folder-resource';

export class WorkPackageEdocFolderCollectionResource extends CollectionResource {
  public $initialize(source:any) {
    super.$initialize(source);

    this.elements = this.elements || [];
  }
}

export interface WorkPackageEdocFolderCollectionResource {
  elements:WorkPackageEdocFolderResource[];
}
