import { Controller } from '@hotwired/stimulus';

export function isElectronUserAgent(userAgent:string):boolean {
  const normalizedUserAgent = userAgent.toLowerCase();
  const isWxWork = normalizedUserAgent.includes('wxwork') || normalizedUserAgent.includes('micromessenger');

  return normalizedUserAgent.includes('electron') && !isWxWork;
}

export default class ElectronHeaderSpacingController extends Controller<HTMLElement> {
  static classes = ['electron', 'windowsElectron'];

  declare readonly electronClass:string;
  declare readonly hasElectronClass:boolean;
  declare readonly windowsElectronClass:string;
  declare readonly hasWindowsElectronClass:boolean;

  connect():void {
    const electron = isElectronUserAgent(navigator.userAgent);
    const windowsElectron = electron && navigator.platform.toLowerCase().startsWith('win');

    if (this.hasElectronClass) {
      this.element.classList.toggle(this.electronClass, electron);
    }

    if (this.hasWindowsElectronClass) {
      this.element.classList.toggle(this.windowsElectronClass, windowsElectron);
    }
  }
}
