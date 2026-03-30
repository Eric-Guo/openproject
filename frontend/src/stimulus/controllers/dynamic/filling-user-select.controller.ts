import { Controller } from '@hotwired/stimulus';

export default class FillingUserSelectController extends Controller {
  static values = {
    url: String,
    prevDay: Number,
  };

  declare readonly urlValue:string;
  declare readonly prevDayValue:number;

  navigate() {
    const select = this.element as HTMLSelectElement;
    window.location.href = `${this.urlValue}?filling_user_id=${select.value}&prev_day=${this.prevDayValue}`;
  }
}
