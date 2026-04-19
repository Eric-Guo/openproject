import { inject, Injectable, DOCUMENT } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { debugLog } from 'core-app/shared/helpers/debug_output';

@Injectable({ providedIn: 'root' })
export class ActiveWindowService {
  private activeState$ = new BehaviorSubject<boolean>(true);
  private document = inject(DOCUMENT);

  constructor() {
    this.document.addEventListener('visibilitychange', () => {
      if (this.document.visibilityState) {
        debugLog(`Browser window has visibility state changed to ${this.document.visibilityState}`);
        this.activeState$.next(this.document.visibilityState === 'visible');
      }
    });
  }

  /**
   * Returns whether the browser window/tab is active
   */
  public get isActive():boolean {
    return this.activeState$.value;
  }

  /**
   * Observable for notifying when visibility changes
   */
  public get active$():Observable<boolean> {
    return this.activeState$.asObservable();
  }
}
