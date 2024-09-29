import { Controller } from '@hotwired/stimulus';

export default class ThKeyinSummaryController extends Controller {
  static targets = ['drawingHourSum', 'discussingHourSum'];

  declare readonly drawingHourSumTarget:HTMLSpanElement;
  declare readonly discussingHourSumTarget:HTMLSpanElement;

  private drawing_inputs:HTMLInputElement[];
  private discussing_inputs:HTMLInputElement[];

  connect() {
    this.drawing_inputs = Array.from(this.element.querySelectorAll('input[name="time_entry[today_drawing_entry][]"]'));
    this.discussing_inputs = Array.from(this.element.querySelectorAll('input[name="time_entry[today_discussing_entry][]"]'));

    this.calculateDrawingHour();
    this.calculateDiscussingHour();

    this.drawing_inputs.forEach((input:HTMLInputElement) => {
      input.addEventListener('input', this.calculateDrawingHour.bind(this));
    });
    this.discussing_inputs.forEach((input:HTMLInputElement) => {
      input.addEventListener('input', this.calculateDiscussingHour.bind(this));
    });
  }

  disconnect() {
    this.drawing_inputs.forEach((input:HTMLInputElement) => {
      input.removeEventListener('input', this.calculateDrawingHour.bind(this));
    });
    this.discussing_inputs.forEach((input:HTMLInputElement) => {
      input.removeEventListener('input', this.calculateDiscussingHour.bind(this));
    });
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
  }
}
