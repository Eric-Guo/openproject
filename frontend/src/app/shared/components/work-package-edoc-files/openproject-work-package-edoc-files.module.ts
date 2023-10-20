import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { IconModule } from 'core-app/shared/components/icon/icon.module';

import { OpWorkPackageEdocFilesComponent } from './work-package-edoc-files.component';
import { OpWorkPackageEdocFileListComponent } from './work-package-edoc-file-list/work-package-edoc-file-list.component';
import { OpWorkPackageEdocFileListItemComponent } from './work-package-edoc-file-list/work-package-edoc-file-list-item.component';
import { OpWorkPackageEdocUploadFileListComponent } from './work-package-edoc-upload-file-list/work-package-edoc-upload-file-list.component';
import { OpWorkPackageEdocUploadFileListItemComponent } from './work-package-edoc-upload-file-list/work-package-edoc-upload-file-list-item.component';

@NgModule({
  imports: [
    CommonModule,
    IconModule,
  ],
  declarations: [
    OpWorkPackageEdocFilesComponent,
    OpWorkPackageEdocFileListComponent,
    OpWorkPackageEdocFileListItemComponent,
    OpWorkPackageEdocUploadFileListComponent,
    OpWorkPackageEdocUploadFileListItemComponent,
  ],
  exports: [
    OpWorkPackageEdocFileListComponent,
    OpWorkPackageEdocFilesComponent,

    OpWorkPackageEdocFileListItemComponent,

    OpWorkPackageEdocUploadFileListComponent,
    OpWorkPackageEdocUploadFileListItemComponent,
  ],
})
export class OpenprojectWorkPackageEdocFilesModule {
}
