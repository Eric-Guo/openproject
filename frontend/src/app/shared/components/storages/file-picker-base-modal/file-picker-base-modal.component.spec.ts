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

import { ChangeDetectorRef, Component, ElementRef, ChangeDetectionStrategy } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import {
  Observable,
  config,
  of,
  throwError,
} from 'rxjs';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { FilePickerBaseModalComponent, } from 'core-app/shared/components/storages/file-picker-base-modal/file-picker-base-modal.component';
import { StorageFileListItem } from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import { type Mock, vi } from 'vitest';
import { edocDds, nextcloud } from 'core-app/shared/components/storages/storages-constants.const';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'test-file-picker',
  template: '',
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class TestFilePickerBaseModalComponent extends FilePickerBaseModalComponent {
  public loadDirectory(directory:IStorageFile):void {
    this.changeLevel(directory);
  }

  protected storageFileToListItem(_file:IStorageFile, _index:number):StorageFileListItem {
    return {} as StorageFileListItem;
  }
}

describe('FilePickerBaseModalComponent', () => {
  interface Spies {
    detectChanges:Mock;
    close:Mock;
    file?:Mock;
    files:Mock;
    reset:Mock;
  }

  function buildComponent(spies:Spies, localsOverride:Record<string, unknown> = {}) {
    const locals = {
      service: { close: spies.close },
      storage: {
        name: 'Storage',
        _links: {
          type: { href: 'urn:openproject:test-storage' },
          self: { href: '/api/v3/storages/1' },
        },
      },
      projectFolderMode: 'inactive',
      ...localsOverride,
    };

    TestBed.configureTestingModule({
      declarations: [TestFilePickerBaseModalComponent],
      providers: [
        { provide: OpModalLocalsToken, useValue: locals },
        { provide: ChangeDetectorRef, useValue: { detectChanges: spies.detectChanges } },
        { provide: ElementRef, useValue: { nativeElement: document.createElement('div') } },
        { provide: SortFilesPipe, useValue: { transform: (files:IStorageFile[]) => files } },
        { provide: StorageFilesResourceService, useValue: { file: spies.file, files: spies.files, reset: spies.reset } },
      ],
    });

    const component = TestBed.runInInjectionContext(() => new TestFilePickerBaseModalComponent());
    component.ngOnInit();

    return { component };
  }

  afterEach(() => TestBed.resetTestingModule());

  function directory(name:string, location:string):IStorageFile {
    return {
      id: location,
      name,
      location,
      mimeType: 'application/x-op-directory',
      permissions: ['readable', 'writeable'],
    };
  }

  it.each([
    {
      dialog: 'link existing files',
      locals: { projectFolderMode: 'manual', projectFolderHref: '/api/v3/storages/1/files/folder:100' },
    },
    { dialog: 'upload a new file', locals: { workPackageId: '450344' } },
  ])('keeps $dialog navigation within the opening DDS folder', ({ locals }) => {
    const root = directory('DDS', '/');
    const entry = directory('Opening folder', '/folder:100');
    const child = directory('Child', '/folder:200');
    const grandchild = directory('Grandchild', '/folder:300');
    const sibling = directory('Sibling', '/folder:400');
    const collection = (parent:IStorageFile, children:IStorageFile[]) => of({
      files: children,
      parent,
      ancestors: [root],
      _type: 'StorageFiles',
      _links: {},
    });
    const files = vi.fn()
      .mockReturnValueOnce(collection(entry, [child, sibling]))
      .mockReturnValueOnce(collection(child, [grandchild]))
      .mockReturnValueOnce(collection(grandchild, []))
      .mockReturnValueOnce(collection(child, [grandchild]))
      .mockReturnValueOnce(collection(entry, [child, sibling]))
      .mockReturnValueOnce(collection(sibling, []));
    const { component } = buildComponent({
      detectChanges: vi.fn(),
      close: vi.fn(),
      file: vi.fn().mockReturnValue(of(entry)),
      files,
      reset: vi.fn(),
    }, {
      ...locals,
      storage: {
        name: 'DDS',
        _links: {
          type: { href: edocDds },
          self: { href: '/api/v3/storages/1' },
        },
      },
    });
    const breadcrumbNames = () => component.breadcrumbs.crumbs.map((crumb) => crumb.text);

    expect(breadcrumbNames()).toEqual(['Opening folder']);

    component.loadDirectory(child);
    expect(breadcrumbNames()).toEqual(['Opening folder', 'Child']);

    component.loadDirectory(grandchild);
    expect(breadcrumbNames()).toEqual(['Opening folder', 'Child', 'Grandchild']);

    component.breadcrumbs.crumbs[1].navigate?.();
    expect(files).toHaveBeenLastCalledWith({
      href: '/api/v3/storages/1/files?parent=/folder:200',
      title: 'Storage files',
    });
    expect(breadcrumbNames()).toEqual(['Opening folder', 'Child']);

    component.breadcrumbs.crumbs[0].navigate?.();
    expect(files).toHaveBeenLastCalledWith({
      href: '/api/v3/storages/1/files?parent=/folder:100',
      title: 'Storage files',
    });
    expect(breadcrumbNames()).toEqual(['Opening folder']);

    component.loadDirectory(sibling);
    expect(breadcrumbNames()).toEqual(['Opening folder', 'Sibling']);
  });

  it('preserves ancestor navigation for other storage providers', () => {
    const root = directory('Root', '/');
    const entry = directory('Project folder', '/project');
    const files = vi.fn().mockReturnValue(of({
      files: [],
      parent: entry,
      ancestors: [root],
      _type: 'StorageFiles',
      _links: {},
    }));
    const { component } = buildComponent({
      detectChanges: vi.fn(),
      close: vi.fn(),
      file: vi.fn().mockReturnValue(of(entry)),
      files,
      reset: vi.fn(),
    }, {
      projectFolderMode: 'manual',
      projectFolderHref: '/api/v3/storages/1/files/project',
      storage: {
        name: 'Nextcloud',
        _links: {
          type: { href: nextcloud },
          self: { href: '/api/v3/storages/1' },
        },
      },
    });

    expect(component.breadcrumbs.crumbs.map((crumb) => crumb.text)).toEqual(['Nextcloud', 'Project folder']);

    component.breadcrumbs.crumbs[0].navigate?.();
    expect(files).toHaveBeenLastCalledWith({ href: '/api/v3/storages/1/files', title: 'Storage files' });
  });

  it('loads the Edoc DDS work package folder on initial open', () => {
    const storageFiles = {
      files: [],
      parent: {
        id: 'folder:450344',
        name: '工作包#450344',
        location: '/folder%3A450344',
        mimeType: 'application/x-op-directory',
        permissions: ['readable', 'writeable'],
      },
      ancestors: [],
      _type: 'StorageFiles',
      _links: {},
    };
    const files = vi.fn().mockReturnValue(of(storageFiles));

    buildComponent({
      detectChanges: vi.fn(),
      close: vi.fn(),
      files,
      reset: vi.fn(),
    }, {
      workPackageId: '450344',
      storage: {
        name: 'Storage',
        _links: {
          type: { href: edocDds },
          self: { href: '/api/v3/storages/1' },
        },
      },
    });

    expect(files).toHaveBeenCalledWith({
      href: '/api/v3/storages/1/files?workPackageId=450344',
      title: 'Storage files',
    });
  });

  it('cancels pending directory loading on destroy', () => {
    const teardown = vi.fn();
    const files$ = new Observable(() => teardown);
    const directory = { location: '/folder', mimeType: 'application/x-op-directory' } as IStorageFile;
    const files = vi.fn().mockReturnValue(files$);
    const { component } = buildComponent({
      detectChanges: vi.fn(),
      close: vi.fn(),
      files,
      reset: vi.fn(),
    });

    component.loadDirectory(directory);

    expect(files).toHaveBeenCalledTimes(2);
    expect(teardown).not.toHaveBeenCalled();

    component.ngOnDestroy();

    expect(teardown).toHaveBeenCalledTimes(1);
  });

  it('does not report directory loading errors as unhandled async exceptions', async () => {
    const previousUnhandledError = config.onUnhandledError;
    const onUnhandledError = vi.fn();
    const files$ = throwError(() => new Error('boom'));
    const detectChanges = vi.fn();
    const directory = { location: '/folder', mimeType: 'application/x-op-directory' } as IStorageFile;
    const { component } = buildComponent({
      detectChanges,
      close: vi.fn(),
      files: vi.fn().mockReturnValue(files$),
      reset: vi.fn(),
    });

    config.onUnhandledError = onUnhandledError;

    component.loadDirectory(directory);
    await new Promise((resolve) => window.setTimeout(resolve));

    expect(component.loading$.getValue()).toBe('error');
    expect(detectChanges).toHaveBeenCalledWith();
    expect(onUnhandledError).not.toHaveBeenCalled();

    config.onUnhandledError = previousUnhandledError;
  });
});
