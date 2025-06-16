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

import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  IDynamicFieldGroupConfig,
  IOPFormlyFieldSettings,
  IOPFormlyTemplateOptions,
} from 'core-app/shared/components/dynamic-forms/typings';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';
import {
  DynamicFormComponent,
} from 'core-app/shared/components/dynamic-forms/components/dynamic-form/dynamic-form.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { JobStatusModalService } from 'core-app/features/job-status/job-status-modal.service';

export interface ProjectTemplateOption {
  href:string|null;
  name:string;
}

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './new-project.component.html',
  styleUrls: ['./new-project.component.sass'],
})
export class NewProjectComponent extends UntilDestroyedMixin implements OnInit {
  formUrl:string|null;

  resourcePath:string;

  dynamicFieldsSettingsPipe = this.fieldSettingsPipe.bind(this);

  fieldGroups:IDynamicFieldGroupConfig[];

  initialPayload:Record<string, unknown> = {};

  text = {
    use_template: this.I18n.t('js.project.use_template'),
    no_template_selected: this.I18n.t('js.project.no_template_selected'),
    advancedSettingsLabel: this.I18n.t('js.forms.advanced_settings'),
    copySettingsLabel: this.I18n.t('js.project.copy.copy_options'),
  };

  hiddenFields:string[] = [
    'identifier',
    'active',
    'createdAt',
  ];

  copyableTemplateFilter = new ApiV3FilterBuilder()
    .add('user_action', '=', ['projects/copy']) // no null values
    .add('templated', '=', true);

  templateOptions$:Observable<ProjectTemplateOption[]> = this
    .apiV3Service
    .projects
    .filtered(
      this.copyableTemplateFilter,
      {
        pageSize: '-1',
        select: 'elements/id, elements/name, elements/identifier, elements/self, elements/ancestors, total, count, pageSize',
      },
    )
    .get()
    .pipe(
      map((response) => response.elements.map((el:HalResource) => ({ href: el.href, name: el.name }))),
    );

  templateForm = new UntypedFormGroup({
    template: new UntypedFormControl(),
  });

  get templateControl() {
    return this.templateForm.get('template');
  }

  @ViewChild(DynamicFormComponent) dynamicForm:DynamicFormComponent;

  constructor(
    private apiV3Service:ApiV3Service,
    private pathHelperService:PathHelperService,
    private jobStatusModalService:JobStatusModalService,
    private I18n:I18nService,
  ) {
    super();
  }

  ngOnInit():void {
    this.resourcePath = this.apiV3Service.projects.path;
    this.fieldGroups = [{
      name: this.text.advancedSettingsLabel,
      fieldsFilter: (field) => !this.isMeta(field.templateOptions?.property)
        && !this.isPrimaryAttribute(field.templateOptions),
    },
    {
      name: this.text.copySettingsLabel,
      fieldsFilter: (field:IOPFormlyFieldSettings) => this.isMeta(field.templateOptions?.property),
    }];

    const urlParams = new URLSearchParams(window.location.search);

    if (urlParams.has('parent_id')) {
      this.setParentAsPayload(urlParams.get('parent_id') as string);
    }
  }

  onSubmitted(response:HalSource) {
    if (response._type === 'JobStatus') {
      this.jobStatusModalService.show(response.jobId as string);
    } else {
      window.location.href = this.pathHelperService.projectPath(response.identifier as string);
    }
  }

  onTemplateSelected(selected:{ href:string|null }) {
    this.initialPayload = {
      ...this.initialPayload,
      name: this.dynamicForm.model.name,
      _meta: {
        ...(this.initialPayload?._meta as Record<string, unknown>),
        sendNotifications: false,
      },
    };
    this.formUrl = selected?.href ? `${selected.href}/copy` : null;
  }

  private isHiddenField(key:string|undefined):boolean {
    // We explicitly want to show the sendNotifications param
    if (key === '_meta.sendNotifications') {
      return false;
    }

    return !!key && (this.hiddenFields.includes(key) || this.isMeta(key));
  }

  private isMeta(property:string|undefined):boolean {
    return !!property && (property.startsWith('copy') || property === 'sendNotifications');
  }

  private isPrimaryAttribute(templateOptions?:IOPFormlyTemplateOptions):boolean {
    if (!templateOptions) {
      return false;
    }

    const nameOrParent = ['name', 'parent'].includes(templateOptions.property!);
    const noPayload = templateOptions.payloadValue == null
      || templateOptions.payloadValue?.href == null;

    return (templateOptions.required && !templateOptions.hasDefault && noPayload) || nameOrParent;
  }

  private setParentAsPayload(parentId:string) {
    const href = this.apiV3Service.projects.id(parentId).path;

    this.initialPayload = {
      _links: {
        parent: {
          href,
        },
      },
    };
  }

  private fieldSettingsPipe(dynamicFieldsSettings:IOPFormlyFieldSettings[]):IOPFormlyFieldSettings[] {
    return dynamicFieldsSettings.map((field) => ({ ...field, hide: this.isHiddenField(field.key) }));
  }
}
