//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectorRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { vi } from 'vitest';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { IProjectStorage } from 'core-app/core/state/project-storages/project-storage.model';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { FilePickerModalComponent } from 'core-app/shared/components/storages/file-picker-modal/file-picker-modal.component';
import { StorageInformationService } from 'core-app/shared/components/storages/storage-information/storage-information.service';
import { edocDds } from 'core-app/shared/components/storages/storages-constants.const';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { StorageComponent } from './storage.component';

describe('StorageComponent', () => {
  let component:StorageComponent;
  const show = vi.fn();
  const requestStream = vi.fn();

  beforeEach(() => {
    show.mockReset();
    requestStream.mockReset().mockResolvedValue({});
    TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: { show } },
        { provide: TurboRequestsService, useValue: { requestStream } },
        ...[
          ChangeDetectorRef,
          ToastService,
          OpUploadService,
          TimezoneService,
          PathHelperService,
          StoragesResourceService,
          FileLinksResourceService,
          StorageInformationService,
          StorageFilesResourceService,
        ].map((provide) => ({ provide, useValue: {} })),
      ],
    });

    component = TestBed.runInInjectionContext(() => new StorageComponent());
    component.resource = {
      id: '450344',
      $links: {
        addFileLink: { href: '/api/v3/work_packages/450344/file_links' },
        fileLinks: { href: '/api/v3/work_packages/450344/file_links' },
      },
    } as unknown as WorkPackageResource;
    component.storage = of({ id: 1, _links: { type: { href: edocDds } } } as IStorage);
    component.fileLinks = of([]);
    component.projectStorage = {
      projectFolderMode: 'inactive',
      _links: { projectDocumentFolder: { href: '/api/v3/storages/1/files/folder:11422810' } },
    } as IProjectStorage;
  });

  afterEach(() => TestBed.resetTestingModule());

  it('opens the server dialog for the current work package when DDS sharing is available', () => {
    component.projectStorage._links.createExternalShare = { href: '/storages/project_storages/7/external_shares/new' };

    expect(component.canCreateExternalShare).toBe(true);
    component.openExternalShareDialog();

    expect(requestStream).toHaveBeenCalledWith('/storages/project_storages/7/external_shares/new?work_package_id=450344');
  });

  it('does not offer sharing without the capability or editing permission', () => {
    expect(component.canCreateExternalShare).toBe(false);
    component.openExternalShareDialog();
    component.projectStorage._links.createExternalShare = { href: '/share' };
    component.allowLinking = false;
    expect(component.canCreateExternalShare).toBe(false);
    component.openExternalShareDialog();
    expect(requestStream).not.toHaveBeenCalled();
  });

  it('links existing files from the project document folder without requesting a work package folder', () => {
    component.openLinkFilesDialog();

    expect(show).toHaveBeenCalledWith(FilePickerModalComponent, 'global', expect.objectContaining({
      projectFolderHref: '/api/v3/storages/1/files/folder:11422810',
      projectFolderMode: 'manual',
      addFileLinksHref: '/api/v3/work_packages/450344/file_links',
    }));
    expect(show.mock.calls[0][2]).not.toHaveProperty('workPackageId');
  });

  it('uses the configured storage folder when no project document folder is available', () => {
    component.projectStorage.projectFolderMode = 'manual';
    component.projectStorage._links.projectFolder = { href: '/api/v3/storages/1/files/folder:100' };
    delete component.projectStorage._links.projectDocumentFolder;

    component.openLinkFilesDialog();

    expect(show).toHaveBeenCalledWith(FilePickerModalComponent, 'global', expect.objectContaining({
      projectFolderHref: '/api/v3/storages/1/files/folder:100',
      projectFolderMode: 'manual',
    }));
    expect(show.mock.calls[0][2]).not.toHaveProperty('workPackageId');
  });
});
