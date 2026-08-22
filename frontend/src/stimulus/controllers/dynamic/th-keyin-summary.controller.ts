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

import { Controller } from '@hotwired/stimulus';

export default class ThKeyinSummaryController extends Controller {
  static targets = ['drawingHourSum', 'discussingHourSum', 'travelHourSum'];

  declare readonly drawingHourSumTarget:HTMLSpanElement;
  declare readonly discussingHourSumTarget:HTMLSpanElement;
  declare readonly travelHourSumTarget:HTMLSpanElement;

  private drawing_inputs:HTMLInputElement[];
  private discussing_inputs:HTMLInputElement[];
  private travel_inputs:HTMLInputElement[];
  private user_keyin_data_but_not_save:boolean;
  private keyin_form:HTMLFormElement = document.getElementById('th-keyin-form') as HTMLFormElement;

  connect() {
    this.drawing_inputs = Array.from(this.element.querySelectorAll('input[name="time_entry[today_drawing_entry][]"]'));
    this.discussing_inputs = Array.from(this.element.querySelectorAll('input[name="time_entry[today_discussing_entry][]"]'));
    this.travel_inputs = Array.from(this.element.querySelectorAll('input[name="time_entry[today_travel_entry][]"]'));

    this.calculateDrawingHour();
    this.calculateDiscussingHour();
    this.calculateTravelHour();
    this.user_keyin_data_but_not_save = false;

    this.drawing_inputs.forEach((input:HTMLInputElement) => {
      input.addEventListener('input', this.calculateDrawingHour.bind(this));
    });
    this.discussing_inputs.forEach((input:HTMLInputElement) => {
      input.addEventListener('input', this.calculateDiscussingHour.bind(this));
    });
    this.travel_inputs.forEach((input:HTMLInputElement) => {
      input.addEventListener('input', this.calculateTravelHour.bind(this));
    });
    window.addEventListener('beforeunload', this.handleBeforeUnload.bind(this));
    this.keyin_form.addEventListener('submit', this.handleSubmit.bind(this));
  }

  disconnect() {
    this.drawing_inputs.forEach((input:HTMLInputElement) => {
      input.removeEventListener('input', this.calculateDrawingHour.bind(this));
    });
    this.discussing_inputs.forEach((input:HTMLInputElement) => {
      input.removeEventListener('input', this.calculateDiscussingHour.bind(this));
    });
    this.travel_inputs.forEach((input:HTMLInputElement) => {
      input.removeEventListener('input', this.calculateTravelHour.bind(this));
    });
    window.removeEventListener('beforeunload', this.handleBeforeUnload.bind(this));
    this.keyin_form.removeEventListener('submit', this.handleSubmit.bind(this));
  }

  calculateDrawingHour() {
    let sum = 0;
    this.drawing_inputs.forEach((input:HTMLInputElement) => {
      const value = parseFloat(input.value);
      if (!Number.isNaN(value)) {
        sum += value;
      }
    });
    this.drawingHourSumTarget.textContent = `${I18n.t('js.labour_keyin.drawing_hour')}: ${sum.toFixed(1)}`;
    this.user_keyin_data_but_not_save = true;
  }

  calculateDiscussingHour() {
    let sum = 0;
    this.discussing_inputs.forEach((input:HTMLInputElement) => {
      const value = parseFloat(input.value);
      if (!Number.isNaN(value)) {
        sum += value;
      }
    });
    this.discussingHourSumTarget.textContent = `${I18n.t('js.labour_keyin.discussing_hour')}: ${sum.toFixed(1)}`;
    this.user_keyin_data_but_not_save = true;
  }

  calculateTravelHour() {
    let sum = 0;
    this.travel_inputs.forEach((input:HTMLInputElement) => {
      const value = parseFloat(input.value);
      if (!Number.isNaN(value)) {
        sum += value;
      }
    });
    this.travelHourSumTarget.textContent = `${I18n.t('js.labour_keyin.travel_hour')}: ${sum.toFixed(1)}`;
    this.user_keyin_data_but_not_save = true;
  }

  private handleBeforeUnload(event:BeforeUnloadEvent) {
    if (this.user_keyin_data_but_not_save) {
      event.preventDefault();
      // Custom message (note: modern browsers will ignore this and show their own message)
      event.returnValue = I18n.t('js.labour_keyin.leave_without_save');
      return event.returnValue;
    }
  }

  private handleSubmit(_event:SubmitEvent) {
    this.user_keyin_data_but_not_save = false;
  }
}
