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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Injectable({ providedIn: 'root' })
export class CurrentProjectService {
  private currentId:string|null = null;
  private currentName:string|null = null;
  private currentIdentifier:string|null = null;
  private currentThCode:string|null = null;
  private currentThName:string|null = null;
  private currentThDocLink:string|null = null;
  private currentThTypeId:number|null = null;

  constructor(
    private PathHelper:PathHelperService,
    private apiV3Service:ApiV3Service,
  ) {
    this.detect();
  }

  public get inProjectContext():boolean {
    return this.currentId !== null;
  }

  public get path():string|null {
    if (this.currentIdentifier) {
      return this.PathHelper.projectPath(this.currentIdentifier);
    }

    return null;
  }

  public get apiv3Path():string|null {
    if (this.currentId) {
      return this.apiV3Service.projects.id(this.currentId).toString();
    }

    return null;
  }

  public get id():string|null {
    return this.currentId;
  }

  public get name():string|null {
    return this.currentName;
  }

  public get identifier():string|null {
    return this.currentIdentifier;
  }

  public get thCode():string|null {
    return this.currentThCode;
  }

  public get thName():string|null {
    return this.currentThName;
  }

  public get thDocLink():string|null {
    return this.currentThDocLink;
  }

  public get thTypeId():number|null {
    return this.currentThTypeId;
  }

  public get ddsFolderId():number|null {
    const reg = /^https?:\/\/edoc\.thape\.com\.cn:8022\/index\.html#doc\/enterprise\/(\d+)/;

    if (!this.thDocLink || !reg.test(this.thDocLink)) return null;
    const match = this.thDocLink.match(reg);
    return Number(match![1]);
  }

  /**
   * Detect the current project from its meta tag.
   */
  public detect() {
    const element:HTMLMetaElement|null = document.querySelector('meta[name=current_project]');
    if (element) {
      this.currentId = element.dataset.projectId as string;
      this.currentName = element.dataset.projectName as string;
      this.currentIdentifier = element.dataset.projectIdentifier as string;
      this.currentThCode = element.dataset.projectThCode as string;
      this.currentThName = element.dataset.projectThName as string;
      this.currentThDocLink = element.dataset.projectThDocLink as string;
      this.currentThTypeId = element.dataset.projectThTypeId ? Number(element.dataset.projectThTypeId) : null;
    } else {
      this.currentId = null;
      this.currentName = null;
      this.currentIdentifier = null;
      this.currentThCode = null;
      this.currentThName = null;
      this.currentThDocLink = null;
      this.currentThTypeId = null;
    }
  }
}
