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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import { showErrorToast } from 'core-stimulus/helpers/toast-helpers';

export default class IfcModelDirectUploadController extends Controller<HTMLFormElement> {
  static targets = ['fileInput', 'defaultModel', 'submitButton'];

  static values = {
    setModelTitleUrl: String,
    maxSize: Number,
    tooLargeMessage: String,
  };

  declare readonly setModelTitleUrlValue:string;
  declare readonly maxSizeValue:number;
  declare readonly tooLargeMessageValue:string;
  declare readonly fileInputTarget:HTMLInputElement;
  declare readonly defaultModelTarget:HTMLInputElement;
  declare readonly submitButtonTarget:HTMLButtonElement;

  connect():void {
    this.validateFile();
    this.submitButtonTarget.disabled = false;
  }

  validateFile():void {
    const file = this.fileInputTarget.files?.[0];
    const tooLarge = file !== undefined && file.size > this.maxSizeValue;
    this.fileInputTarget.setCustomValidity(tooLarge ? this.tooLargeMessageValue : '');
    if (tooLarge) this.fileInputTarget.reportValidity();
  }

  async upload(event:SubmitEvent):Promise<void> {
    event.preventDefault();
    const file = this.fileInputTarget.files?.[0];
    if (!file || this.element.inert) return;

    this.element.inert = true;
    try {
      const response = await post(this.setModelTitleUrlValue, {
        body: {
          title: file.name.split('.').slice(0, -1).join('.'),
          fileSize: String(file.size),
          isDefault: String(this.defaultModelTarget.checked),
        },
        responseKind: 'json',
      });

      if (response.ok) {
        this.element.submit();
      } else if (response.unprocessableEntity) {
        const { error } = await response.json as { error:string };
        this.fileInputTarget.setCustomValidity(error);
        this.element.inert = false;
        this.fileInputTarget.reportValidity();
      } else {
        showErrorToast();
      }
    } catch {
      showErrorToast();
    } finally {
      this.element.inert = false;
    }
  }
}
