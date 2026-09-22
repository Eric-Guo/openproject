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

import ThMeetingFormController from './th-meeting-form.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('ThMeetingFormController', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:ReturnType<typeof vi.fn>;

  beforeEach(async () => {
    fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve([{ id: 'room-1', name: 'Shanghai - Room 1' }]),
    });
    vi.stubGlobal('fetch', fetchSpy);
    ctx = await setupStimulusTest({ controllers: { 'th-meeting-form': ThMeetingFormController } });
    await ctx.mount(`
      <form data-controller="th-meeting-form"
            data-th-meeting-form-available-rooms-path-value="/th_meetings/available_rooms"
            data-th-meeting-form-th-meeting-id-value="booking-1">
        <input id="meeting_start_date" value="2026-09-08">
        <input id="meeting_start_time_hour" value="14:00">
        <input id="meeting_duration" value="2h">
        <select id="meeting_th_meeting_upstream_room_id" aria-label="Meeting room">
          <option value="">Select meeting room</option>
          <option value="room-1" selected>Shanghai - Room 1</option>
          <option value="room-2">Shanghai - Room 2</option>
        </select>
        <button type="button" data-action="click->th-meeting-form#getAvailableRooms">Refresh rooms</button>
      </form>
    `);
  });

  afterEach(() => {
    ctx.dispose();
    vi.unstubAllGlobals();
  });

  it('refreshes rooms for the full formatted duration and keeps an available selection', async () => {
    ctx.screen.getByRole('button', { name: 'Refresh rooms' }).click();

    await vi.waitFor(() => expect(ctx.screen.queryByRole('option', { name: 'Shanghai - Room 2' })).toBeNull());

    const url = fetchSpy.mock.calls[0][0] as URL;
    expect(url.searchParams.get('start_date_time')).toEqual('2026-09-08 14:00:00');
    expect(url.searchParams.get('end_date_time')).toEqual('2026-09-08 16:00:00');
    expect(url.searchParams.get('th_meeting_id')).toEqual('booking-1');
    expect(ctx.screen.getByRole<HTMLSelectElement>('combobox').value).toEqual('room-1');
  });

  it('clears a selection that is no longer available', async () => {
    const select = ctx.screen.getByRole<HTMLSelectElement>('combobox');
    select.value = 'room-2';
    ctx.screen.getByRole('button', { name: 'Refresh rooms' }).click();

    await vi.waitFor(() => expect(select.value).toEqual(''));
    expect(ctx.screen.getByRole('option', { name: 'Shanghai - Room 1' })).toBeTruthy();
  });

  it('preserves the current room options when the request fails', async () => {
    fetchSpy.mockResolvedValue({ ok: false, status: 503 });
    const button = ctx.screen.getByRole('button', { name: 'Refresh rooms' });
    button.click();

    await vi.waitFor(() => expect(button.textContent).toEqual('数据获取失败！'));
    expect(ctx.screen.getByRole('option', { name: 'Shanghai - Room 2' })).toBeTruthy();
    expect(ctx.screen.getByRole<HTMLSelectElement>('combobox').value).toEqual('room-1');
  });
});
