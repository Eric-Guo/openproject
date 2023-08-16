// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  OnInit,
  ViewChild,
} from '@angular/core';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { Observable } from 'rxjs';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { SchemaAttributeObject } from 'core-app/features/hal/resources/schema-attribute-object';

@Component({
  templateUrl: './project-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class WidgetProjectDetailsComponent extends AbstractWidgetComponent implements OnInit {
  @ViewChild('contentContainer', { static: true }) readonly contentContainer:ElementRef;

  public customFields:{ key:string, label:string }[] = [];

  public profileFields:{ key:string, label:string, value:string, isLink?:boolean }[] = [];

  public project$:Observable<ProjectResource>;

  constructor(protected readonly i18n:I18nService,
    protected readonly injector:Injector,
    protected readonly apiV3Service:ApiV3Service,
    protected readonly currentProject:CurrentProjectService,
    protected readonly cdRef:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit():void {
    this.loadAndRender();
    if (this.currentProject.id) {
      this.project$ = this
        .apiV3Service
        .projects
        .id(this.currentProject.id)
        .requireAndStream();
      this.project$.subscribe((project) => {
        this.setProfileFields(project);
      });
    }
  }

  public get isEditable():boolean {
    return false;
  }

  private loadAndRender():void {
    void Promise.all([
      this.loadProjectSchema(),
    ])
      .then(([schema]) => {
        this.setCustomFields(schema);
      });
  }

  private loadProjectSchema():Promise<SchemaResource> {
    return this
      .apiV3Service
      .projects
      .schema
      .get()
      .toPromise();
  }

  private setCustomFields(schema:SchemaResource) {
    Object.entries(schema).forEach(([key, keySchema]) => {
      if (/customField\d+/.exec(key)) {
        this.customFields.push({ key, label: (keySchema as SchemaAttributeObject).name });
      }
    });

    this.cdRef.detectChanges();
  }

  private setProfileFields(project:ProjectResource) {
    if (this.profileFields.length > 0) return;
    if (project.profile) {
      const typeList = this.i18n.t('js.th_projects.project_profile.type_list');
      this.profileFields.push({ key: 'typeId', label: '天华项目类型', value: typeList[project.profile.typeId] });
      this.profileFields.push({ key: 'name', label: '天华项目名称', value: project.profile.name });
      this.profileFields.push({ key: 'code', label: '天华项目编号', value: project.profile.code });
      this.profileFields.push({ key: 'docLink', label: '天华项目文档', value: project.profile.docLink, isLink: /^https?:\/\/.+/.test(project.profile.docLink) });
    }
  }
}
