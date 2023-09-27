import {
  Directive, ElementRef, Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';

@Directive({
  selector: '[membershipSettingsContextMenu]',
})
export class MembershipSettingsMenuDirective extends OpContextMenuTrigger {
  @Input() public project:ProjectResource;

  @Input() public exportHandle:() => void;

  @Input() public importHandle:() => void;

  @Input() public downloadTemplateHandle:() => void;

  constructor(readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly authorisationService:AuthorisationService,
    readonly I18n:I18nService) {
    super(elementRef, opContextMenu);
  }

  ngAfterViewInit():void {
    super.ngAfterViewInit();
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  public get locals() {
    return {
      contextMenuId: 'settingsDropdown',
      items: this.items,
    };
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    const additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom',
    };

    const position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  public onClose(focus:boolean) {
    if (focus) {
      this.afterFocusOn.focus();
    }
  }

  private buildItems() {
    this.items = [
      {
        disabled: false,
        linkText: ' 导入成员',
        hidden: false,
        icon: 'icon-import',
        onClick: () => {
          this.importHandle?.();
          return true;
        },
      },
      {
        disabled: false,
        linkText: '导出成员',
        hidden: false,
        icon: 'icon-export',
        onClick: () => {
          this.exportHandle?.();
          return true;
        },
      },
      {
        disabled: false,
        linkText: '模板下载',
        hidden: false,
        icon: 'icon-file-sheet',
        onClick: () => {
          this.downloadTemplateHandle?.();
          return true;
        },
      },
    ];
  }
}
