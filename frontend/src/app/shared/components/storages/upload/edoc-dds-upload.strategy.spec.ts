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

import {
  afterEach, beforeEach, describe, expect, it,
} from 'vitest';
import { TestBed } from '@angular/core/testing';
import { HttpClient, provideHttpClient, withXhr } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { lastValueFrom } from 'rxjs';

import { EdocDdsFileUploadResponse, EdocDdsUploadStrategy } from './edoc-dds-upload.strategy';

describe('EdocDdsUploadStrategy', () => {
  let strategy:EdocDdsUploadStrategy;
  let httpMock:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(withXhr()), provideHttpClientTesting()],
    });

    strategy = new EdocDdsUploadStrategy(TestBed.inject(HttpClient));
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it.each([
    ['http://localhost/api/v3/storages/1/files/upload?project_id=501', '/api/v3/storages/1/files/upload?project_id=501'],
    ['https://configured.example/openproject/api/v3/storages/1/files/upload?project_id=501', '/openproject/api/v3/storages/1/files/upload?project_id=501'],
    ['/api/v3/storages/1/files/upload?project_id=501', '/api/v3/storages/1/files/upload?project_id=501'],
  ])('uploads %s to the page origin while preserving the path and query', async (href, path) => {
    const file = new File(['image content'], 'images.png', { type: 'image/png' });
    const response:EdocDdsFileUploadResponse = {
      id: 'file:123', name: file.name, mimeType: file.type, size: file.size,
    };
    const upload = lastValueFrom(strategy.execute<EdocDdsFileUploadResponse>(href, [{
      file,
      location: 'folder:17059116',
    }])[0]);

    const request = httpMock.expectOne(path);
    const body = request.request.body as FormData;
    expect(request.request.method).toBe('POST');
    expect(body.get('file')).toEqual(file);
    expect(body.get('parent')).toBe('folder:17059116');

    request.flush(response);

    await expect(upload).resolves.toMatchObject({ body: response });
  });
});
