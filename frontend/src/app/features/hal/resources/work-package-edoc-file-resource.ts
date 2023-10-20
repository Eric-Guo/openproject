import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export class WorkPackageEdocFileResource extends HalResource {
  // Properties
  public folderId:number;

  public fileId:number;

  public fileName:string;

  public uploadId:string;

  public md5:string;

  public contentType:string;

  public fileSize:number;

  public fileVerId:number;

  public regionHash:string;

  public regionId:number;

  public regionType:number;

  public regionUrl:string;

  public chunks:number;

  public chunkSize:number;

  public status:number;

  public publishPreviewUrl:string;

  public previewUrl:string;

  public createdAt:string;

  public updatedAt:string;

  // Links
  public folder:HalResource;

  public upload:HalResource;

  public user:HalResource;

  public remove?:HalResource;
}
