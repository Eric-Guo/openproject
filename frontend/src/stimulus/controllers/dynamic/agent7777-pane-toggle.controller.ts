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

import { Controller } from '@hotwired/stimulus';

const LOCAL_STORAGE_KEY = 'openProject-agent7777PaneCollapsed';
const COLLAPSED_CLASS = 'agent7777-pane-collapsed';
const AVAILABLE_CLASS = 'with-agent7777';

export default class Agent7777PaneToggleController extends Controller<HTMLElement> {
  static targets = ['button', 'main', 'pane'];

  declare readonly buttonTarget:HTMLButtonElement;
  declare readonly hasButtonTarget:boolean;
  declare readonly mainTarget:HTMLElement;
  declare readonly paneTarget:HTMLElement;

  private observer?:MutationObserver;

  connect():void {
    if (!this.hasButtonTarget) {
      return;
    }

    const collapsed = window.OpenProject.guardedLocalStorage(LOCAL_STORAGE_KEY) === 'true';

    this.setExpanded(!collapsed);
    this.syncAvailability();

    this.observer = new MutationObserver(() => this.syncAvailability());
    this.observer.observe(this.mainTarget, { attributes: true, attributeFilter: ['class'] });
  }

  disconnect():void {
    this.observer?.disconnect();
    this.observer = undefined;
  }

  toggle(event:Event):void {
    event.preventDefault();

    if (!this.mainTarget.classList.contains(AVAILABLE_CLASS)) {
      return;
    }

    const expanded = this.buttonTarget.getAttribute('aria-expanded') === 'true';
    this.setExpanded(!expanded);
    window.OpenProject.guardedLocalStorage(LOCAL_STORAGE_KEY, String(expanded));
  }

  private setExpanded(expanded:boolean):void {
    const label = expanded ? this.buttonTarget.dataset.expandedLabel! : this.buttonTarget.dataset.collapsedLabel!;

    this.mainTarget.classList.toggle(COLLAPSED_CLASS, !expanded);
    this.buttonTarget.setAttribute('aria-expanded', String(expanded));
    this.setButtonLabel(label);
    if (expanded) {
      this.paneTarget.removeAttribute('aria-hidden');
    } else {
      this.paneTarget.setAttribute('aria-hidden', 'true');
    }
  }

  private setButtonLabel(label:string):void {
    const labelledBy = this.buttonTarget.getAttribute('aria-labelledby');
    const tooltip = labelledBy && document.getElementById(labelledBy);

    if (tooltip) {
      tooltip.textContent = label;
    }

    this.buttonTarget.removeAttribute('aria-labelledby');
    this.buttonTarget.setAttribute('aria-label', label);
  }

  private syncAvailability():void {
    this.buttonTarget.hidden = !this.mainTarget.classList.contains(AVAILABLE_CLASS);
  }
}
