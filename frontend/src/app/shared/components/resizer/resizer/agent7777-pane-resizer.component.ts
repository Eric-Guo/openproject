//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ResizeDelta } from 'core-app/shared/components/resizer/resizer.component';

const LOCAL_STORAGE_KEY = 'openProject-agent7777PaneWidth';
const RESIZE_EVENT = 'agent7777-pane-resize';
const MINIMUM_WIDTH = 280;
const MINIMUM_CONTENT_WIDTH = 280;

@Component({
  selector: 'opce-agent7777-pane-resizer',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <op-resizer class="agent7777-pane--resizer"
                [customHandler]="true"
                cursorClass="col-resize"
                (resizeStarted)="resizeStart()"
                (move)="resizeMove($event)"
                (resizeFinished)="resizeEnd()">
      <button
        type="button"
        class="spot-link agent7777-pane--resize-handle"
        aria-label="Resize 7777 agent pane"
      >
        <svg op-resizer-vertical-lines-icon size="small"></svg>
      </button>
    </op-resizer>
  `,
  standalone: false,
})
export class Agent7777PaneResizerComponent {
  private readonly pane = document.querySelector<HTMLElement>('#agent7777-pane')!;
  private elementWidth = 0;
  private maximumWidth = 0;

  public resizeStart():void {
    this.elementWidth = this.pane.clientWidth;
    const contentWidth = document.querySelector<HTMLElement>('#content-wrapper')?.clientWidth ?? MINIMUM_CONTENT_WIDTH;
    this.maximumWidth = Math.max(MINIMUM_WIDTH, this.elementWidth + contentWidth - MINIMUM_CONTENT_WIDTH);
  }

  public resizeMove(deltas:ResizeDelta):void {
    // The handle is on the pane's left edge, so moving left increases its width.
    this.saveWidth(this.elementWidth - deltas.absolute.x);
  }

  public resizeEnd():void {
    window.dispatchEvent(new Event(RESIZE_EVENT));
  }

  private saveWidth(width:number):void {
    const constrainedWidth = Math.min(Math.max(width, MINIMUM_WIDTH), this.maximumWidth);

    document.documentElement.style.setProperty('--agent7777-pane-width', `${constrainedWidth}px`);
    window.OpenProject.guardedLocalStorage(LOCAL_STORAGE_KEY, String(constrainedWidth));
  }
}
