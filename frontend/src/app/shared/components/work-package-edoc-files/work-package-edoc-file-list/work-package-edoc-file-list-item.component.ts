import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { BehaviorSubject, combineLatest, Observable } from 'rxjs';
import { distinctUntilChanged } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IPrincipal } from 'core-app/core/state/principals/principal.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogOptions } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';
import { getIconForMimeType } from 'core-app/shared/components/storages/functions/storages.functions';
import { IFileIcon } from 'core-app/shared/components/storages/icons.mapping';
import { WorkPackageEdocFileResource } from 'core-app/features/hal/resources/work-package-edoc-file-resource';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-work-package-edoc-file-list-item]',
  templateUrl: './work-package-edoc-file-list-item.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpWorkPackageEdocFileListItemComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() public edocFile:WorkPackageEdocFileResource;

  @Input() public index:number;

  @Input() public showCheckbox = false;

  @Input() public hideRemoveButton = false;

  @Output() public handleCheckedChange = new EventEmitter<boolean>();

  @Output() public removeEdocFile = new EventEmitter<void>();

  @ViewChild('avatar') avatar:ElementRef;

  static imageFileExtensions:string[] = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public text = {
    dragHint: this.I18n.t('js.attachments.draggable_hint'),
    deleteTitle: this.I18n.t('js.attachments.delete'),
    deleteConfirmation: this.I18n.t('js.attachments.delete_confirmation'),
    removeFile: (arg:unknown):string => this.I18n.t('js.label_remove_file', arg),
  };

  public get deleteIconTitle():string {
    return this.text.removeFile({ fileName: this.edocFile.fileName });
  }

  public author$:Observable<IPrincipal>;

  public timestampText:string;

  public fileIcon:IFileIcon;

  private viewInitialized$ = new BehaviorSubject<boolean>(false);

  constructor(
    private readonly I18n:I18nService,
    private readonly timezoneService:TimezoneService,
    private readonly confirmDialogService:ConfirmDialogService,
    private readonly principalsResourceService:PrincipalsResourceService,
    private readonly principalRendererService:PrincipalRendererService,
  ) {
    super();
  }

  ngOnInit():void {
    this.fileIcon = getIconForMimeType(this.edocFile.contentType);

    const href = this.edocFile.user.href as string;
    this.author$ = this.principalsResourceService.requireEntity(href);

    this.timestampText = this.timezoneService.parseDatetime(this.edocFile.createdAt).fromNow();

    combineLatest([
      this.author$,
      this.viewInitialized$.pipe(distinctUntilChanged()),
    ]).pipe(this.untilDestroyed())
      .subscribe(([user, initialized]) => {
        if (!initialized) {
          return;
        }

        this.principalRendererService.render(
          this.avatar.nativeElement as HTMLElement,
          user,
          { hide: true, link: false },
          { hide: false, size: 'mini' },
        );
      });
  }

  ngAfterViewInit():void {
    this.viewInitialized$.next(true);
  }

  get linkUrl() {
    return this.edocFile.publishPreviewUrl || this.edocFile.previewUrl;
  }

  /**
   * Set the appropriate data for drag & drop of an attachment item.
   * @param evt DragEvent
   */
  public setDragData(evt:DragEvent):void {
    const url = this.downloadPath;
    const previewElement = this.draggableHTML(url);

    if (evt.dataTransfer == null) return;

    evt.dataTransfer.setData('text/plain', url);
    evt.dataTransfer.setData('text/html', previewElement.outerHTML);
    evt.dataTransfer.setData('text/uri-list', url);
    evt.dataTransfer.setDragImage(previewElement, 0, 0);
  }

  public draggableHTML(url:string):HTMLImageElement|HTMLAnchorElement {
    let el:HTMLImageElement|HTMLAnchorElement;

    if (this.isImage) {
      el = document.createElement('img');
      el.src = url;
      el.textContent = this.edocFile.fileName;
    } else {
      el = document.createElement('a');
      el.href = url;
      el.textContent = this.edocFile.fileName;
    }

    return el;
  }

  private get downloadPath():string {
    return this.edocFile.publishPreviewUrl;
  }

  private get isImage():boolean {
    const ext = this.edocFile.fileName.split('.').pop() || '';
    return OpWorkPackageEdocFileListItemComponent.imageFileExtensions.indexOf(ext.toLowerCase()) > -1;
  }

  public confirmRemoveEdocFile():void {
    const options:ConfirmDialogOptions = {
      text: {
        text: this.text.deleteConfirmation,
        title: this.text.deleteTitle,
        button_continue: this.text.deleteTitle,
      },
      icon: {
        continue: 'delete',
      },
      dangerHighlighting: true,
    };
    void this.confirmDialogService
      .confirm(options)
      .then(() => { this.removeEdocFile.emit(); })
      .catch(() => { /* confirmation rejected */ });
  }

  public checkedChange(checked:boolean):void {
    this.handleCheckedChange.emit(checked);
  }

  public get canRemove() {
    return !this.hideRemoveButton && !!this.edocFile.remove;
  }

  public get invalid() {
    return this.edocFile.status !== 1;
  }
}
