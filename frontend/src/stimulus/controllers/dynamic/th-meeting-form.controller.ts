import { Controller } from '@hotwired/stimulus';

export default class ThMeetingFormController extends Controller {
  static values = {
    thMeetingId: String,
    availableRoomsPath: String,
  };

  declare thMeetingIdValue:string;

  declare availableRoomsPathValue:string;

  connect() {}

  getAvailableRooms(e:MouseEvent) {
    const button = e.target as HTMLButtonElement;
    const buttonText = button.textContent;

    if (!this.availableRoomsPathValue) throw new Error('Available rooms path not found');

    const startDateInput = this.element.querySelector<HTMLInputElement>('#meeting_start_date');

    if (!startDateInput) throw new Error('Start date input not found');

    const startTimeInput = this.element.querySelector<HTMLInputElement>('#meeting-form-start-time');

    if (!startTimeInput) throw new Error('Start time input not found');

    const durationInput = this.element.querySelector<HTMLInputElement>('#meeting-form-duration');

    if (!durationInput) throw new Error('Duration input not found');

    const meetingSelect = this.element.querySelector<HTMLSelectElement>('#meeting_th_meeting_upstream_room_id');

    if (!meetingSelect) throw new Error('Meeting select not found');

    const startDate = moment(`${startDateInput.value} ${startTimeInput.value}`, 'YYYY-MM-DD HH:mm');
    const endDate = startDate.add(durationInput.value, 'hour');
    const thMeetingId = this.thMeetingIdValue;

    const startDateTime = startDate.format('YYYY-MM-DD HH:mm:ss');
    const endDateTime = endDate.format('YYYY-MM-DD HH:mm:ss');

    const url = new URL(this.availableRoomsPathValue, window.location.origin);

    url.searchParams.append('start_date_time', startDateTime);
    url.searchParams.append('end_date_time', endDateTime);
    if (thMeetingId) {
      url.searchParams.append('th_meeting_id', thMeetingId);
    }

    void jQuery.ajax({
      method: 'get',
      url: url.toString(),
      dataType: 'json',
      beforeSend: () => {
        button.disabled = true;
        button.textContent = '数据获取中...';
      },
      success: (data:{ id:string;name:string }[]) => {
        let value = meetingSelect.value;
        const existed = data.some((item) => item.id === value);
        if (!existed) value = '';
        Array.from(meetingSelect.children).forEach((option:HTMLOptionElement) => {
          if (option.value) {
            option.remove();
          }
        });
        data.forEach((item) => {
          const option = document.createElement('option');
          option.value = item.id;
          option.text = item.name;
          meetingSelect.append(option);
        });
        meetingSelect.value = value;
        button.textContent = '数据获取成功！';
      },
      error: () => {
        button.textContent = '数据获取失败！';
      },
      complete: () => {
        setTimeout(() => {
          button.disabled = false;
          button.textContent = buttonText;
        }, 1000);
      },
    });
  }
}
