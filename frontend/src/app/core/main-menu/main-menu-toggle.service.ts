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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@Injectable({ providedIn: 'root' })
export class MainMenuToggleService {
  public toggleTitle:string;

  private elementWidth:number;

  private elementMinWidth = 11;

  private readonly defaultWidth:number = 230;

  private readonly localStorageKey:string = 'openProject-mainMenuWidth';

  private readonly localStorageStateKey:string = 'openProject-mainMenuCollapsed';

  @InjectField() currentProject:CurrentProjectService;

  private global = (window as any);

  private htmlNode = document.getElementsByTagName('html')[0];

  private mainMenu = jQuery('#main-menu')[0]; // main menu, containing sidebar and resizer

  // Title needs to be sync in main-menu-toggle.component.ts and main-menu-resizer.component.ts
  private titleData = new BehaviorSubject<string>('');

  public titleData$ = this.titleData.asObservable();

  // Notes all changes of the menu size (currently needed in wp-resizer.component.ts)
  private changeData = new BehaviorSubject<any>({});

  public changeData$ = this.changeData.asObservable();
  private wasHiddenDueToResize = false;

  private wasCollapsedByUser = false;

  constructor(
    protected I18n:I18nService,
    public injector:Injector,
    readonly deviceService:DeviceService,
  ) {
    this.initializeMenu();
    // Add resize event listener
    window.addEventListener('resize', this.onWindowResize.bind(this));
  }

  public initializeMenu():void {
    if (!this.mainMenu) {
      return;
    }

    this.elementWidth = parseInt(window.OpenProject.guardedLocalStorage(this.localStorageKey) as string);
    const menuCollapsed = window.OpenProject.guardedLocalStorage(this.localStorageStateKey) === 'true';

    // Set the initial value of the collapse tracking flag
    this.wasCollapsedByUser = menuCollapsed;

    if (!this.elementWidth) {
      this.saveWidth(this.mainMenu.offsetWidth);
    } else if (menuCollapsed) {
      this.closeMenu();
    } else {
      this.setWidth();
    }

    this.adjustMenuVisibility();
  }

  private onWindowResize():void {
    this.adjustMenuVisibility();
  }

  private adjustMenuVisibility():void {
    if (window.innerWidth >= 1012) {
      // On larger screens, reopen the menu if it was hidden only due to screen resizing
      if (this.wasHiddenDueToResize && !this.wasCollapsedByUser) {
        this.setWidth(this.defaultWidth);
        this.wasHiddenDueToResize = false; // Reset the flag since the menu is now shown
      }
    } else if (this.showNavigation) {
        this.closeMenu();
        this.wasHiddenDueToResize = true; // Indicate that the menu was hidden due to resize
    }
  }

  public toggleNavigation(event?:JQuery.TriggeredEvent|Event):void {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }

    // Update the user collapse flag and clear `wasHiddenDueToResize`
    this.wasCollapsedByUser = this.showNavigation;
    this.wasHiddenDueToResize = false; // Reset because a manual toggle overrides any resize behavior

    if (this.showNavigation) {
      this.closeMenu();
    } else {
      this.openMenu();
    }

    // Save the collapsed state in localStorage
    window.OpenProject.guardedLocalStorage(this.localStorageStateKey, String(!this.showNavigation));
    // Set focus on first visible main menu item.
    // This needs to be called after AngularJS has rendered the menu, which happens some when after(!) we leave this
    // method here. So we need to set the focus after a timeout.
    setTimeout(() => {
      jQuery('#main-menu [class*="-menu-item"]:visible').first().focus();
    }, 500);
  }

  public closeMenu():void {
    this.setWidth(0);
    jQuery('.searchable-menu--search-input').blur();
  }

  public openMenu():void {
    this.setWidth(this.defaultWidth);
  }

  public setWidth(width?:number):void {
    if (width !== undefined) {
      this.elementWidth = width;
    }

    // Apply the width directly to the main menu
    this.mainMenu.style.width = `${this.elementWidth}px`;

    // Apply to root CSS variable for any related layout adjustments
    this.htmlNode.style.setProperty('--main-menu-width', `${this.elementWidth}px`);

    // Check if menu is open or closed and apply CSS class if needed
    this.toggleClassHidden();
    this.snapBack();
    this.setToggleTitle();

    // Save the width if it's open
    if (this.elementWidth > 0) {
      window.OpenProject.guardedLocalStorage(this.localStorageKey, String(this.elementWidth));
    }
  }

  public saveWidth(width?:number):void {
    this.setWidth(width);
    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(this.elementWidth));
    window.OpenProject.guardedLocalStorage(this.localStorageStateKey, String(this.elementWidth === 0));
  }

  public get showNavigation():boolean {
    return this.elementWidth >= this.elementMinWidth;
  }

  private snapBack():void {
    if (this.elementWidth < this.elementMinWidth) {
      this.elementWidth = 0;
    }
  }

  private setToggleTitle():void {
    if (this.showNavigation) {
      this.toggleTitle = this.I18n.t('js.label_hide_project_menu');
    } else {
      this.toggleTitle = this.I18n.t('js.label_expand_project_menu');
    }
    this.titleData.next(this.toggleTitle);
  }

  private toggleClassHidden():void {
    const isHidden = this.elementWidth < this.elementMinWidth;
    const hideElements = jQuery('.can-hide-navigation');
    hideElements.toggleClass('hidden-navigation', isHidden);
  }
}
