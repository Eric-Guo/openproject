import { Controller } from '@hotwired/stimulus';

export default class ElectronHeaderSpacingController extends Controller<HTMLElement> {
  connect():void {
    const windowsElectron = navigator.userAgent.includes('Electron')
      && navigator.platform.toLowerCase().startsWith('win');

    this.element.classList.toggle('op-app-header--end_windows-electron', windowsElectron);
  }
}
