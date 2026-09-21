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
import moment, { Moment } from 'moment';
import { durationStringToSeconds } from 'core-stimulus/helpers/chronic-duration-helper';

export default class ThMeetingFormController extends Controller {
  static values = {
    thMeetingId: String,
    availableRoomsPath: String,
  };

  declare thMeetingIdValue:string;

  declare availableRoomsPathValue:string;

  async getAvailableRooms(e:MouseEvent):Promise<void> {
    const button = e.currentTarget as HTMLButtonElement;
    const buttonText = button.textContent;

    if (!this.availableRoomsPathValue) throw new Error('Available rooms path not found');

    const startDateInput = this.element.querySelector<HTMLInputElement>('#meeting_start_date');

    if (!startDateInput) throw new Error('Start date input not found');

    const startTimeInput = this.element.querySelector<HTMLInputElement>('#meeting_start_time_hour');

    if (!startTimeInput) throw new Error('Start time input not found');

    const durationInput = this.element.querySelector<HTMLInputElement>('#meeting_duration');

    if (!durationInput) throw new Error('Duration input not found');

    const meetingSelect = this.element.querySelector<HTMLSelectElement>('#meeting_th_meeting_upstream_room_id');

    if (!meetingSelect) throw new Error('Meeting select not found');

    const startDate:Moment = moment(`${startDateInput.value} ${startTimeInput.value}`, 'YYYY-MM-DD HH:mm');
    const endDate:Moment = startDate.clone().add(durationStringToSeconds(durationInput.value), 'seconds');
    const thMeetingId = this.thMeetingIdValue;

    const startDateTime = startDate.format('YYYY-MM-DD HH:mm:ss');
    const endDateTime = endDate.format('YYYY-MM-DD HH:mm:ss');

    const url = new URL(this.availableRoomsPathValue, window.location.origin);

    url.searchParams.append('start_date_time', startDateTime);
    url.searchParams.append('end_date_time', endDateTime);
    url.searchParams.append('show_busy', 'false');
    if (thMeetingId) {
      url.searchParams.append('th_meeting_id', thMeetingId);
    }

    button.disabled = true;
    button.textContent = '数据获取中...';

    try {
      const response = await fetch(url, { headers: { Accept: 'application/json' } });
      if (!response.ok) throw new Error(`Room availability request failed: ${response.status}`);

      const data = await response.json() as { id:string;name:string }[];
      const selectedValue = meetingSelect.value;
      const value = data.some((item) => item.id === selectedValue) ? selectedValue : '';

      Array.from(meetingSelect.options).forEach((option) => {
        if (option.value) option.remove();
      });
      data.forEach((item) => {
        meetingSelect.add(new Option(item.name, item.id));
      });
      meetingSelect.value = value;
      button.textContent = '数据获取成功！';
    } catch {
      button.textContent = '数据获取失败！';
    } finally {
      setTimeout(() => {
        button.disabled = false;
        button.textContent = buttonText;
      }, 1000);
    }
  }
}
