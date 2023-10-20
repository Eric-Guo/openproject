import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageEdocFileCollectionResource } from 'core-app/features/hal/resources/work-package-edoc-file-collection-resource';

export class WorkPackageEdocFolderResource extends HalResource {
  // Properties
  public folderId:number;

  public folderName:number;

  public publishCode:string;

  public publishUrl:string;

  // Links
  public files:WorkPackageEdocFileCollectionResource;

  public create_file:HalResource;
}
