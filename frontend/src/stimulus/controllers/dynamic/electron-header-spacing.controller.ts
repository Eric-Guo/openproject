import { Controller } from '@hotwired/stimulus';

export default class ElectronHeaderSpacingController extends Controller<HTMLElement> {
  static classes = ['electron', 'windowsElectron'];

  declare readonly electronClass:string;
  declare readonly hasElectronClass:boolean;
  declare readonly windowsElectronClass:string;
  declare readonly hasWindowsElectronClass:boolean;

  connect():void {
    const electron = navigator.userAgent.includes('Electron');
    const windowsElectron = electron && navigator.platform.toLowerCase().startsWith('win');

    if (this.hasElectronClass) {
      this.element.classList.toggle(this.electronClass, electron);
    }

    if (this.hasWindowsElectronClass) {
      this.element.classList.toggle(this.windowsElectronClass, windowsElectron);
    }
  }
}
