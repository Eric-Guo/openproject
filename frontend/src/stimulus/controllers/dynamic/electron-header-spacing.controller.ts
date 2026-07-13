import { Controller } from '@hotwired/stimulus';

export default class ElectronHeaderSpacingController extends Controller<HTMLElement> {
  static classes = ['windowsElectron'];

  declare readonly windowsElectronClass:string;

  connect():void {
    const windowsElectron = navigator.userAgent.includes('Electron')
      && navigator.platform.toLowerCase().startsWith('win');

    this.element.classList.toggle(this.windowsElectronClass, windowsElectron);
  }
}
