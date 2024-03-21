import { States } from 'core-app/core/states/states.service';
import {
  ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import * as ExcelJs from 'exceljs';
import { catchError } from 'rxjs';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { StateService } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BackRoutingService } from 'core-app/features/work-packages/components/back-routing/back-routing.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TypeResource } from 'core-app/features/hal/resources/type-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { PromiseTaskQueue } from 'core-app/shared/helpers/promise-task-queue';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { WpImportField, WpImportFieldsMap } from './wp-import.field';

type WpTemplate = Partial<Record<WpImportField, string>>;

type WpTemplateGroup = {
  key:string | number;
  name:string;
  values:WpTemplate[];
};

type WpTemplateRow = {
  value:WpTemplate;
  checked:boolean;
};

const tempData:{
  groups?:WpTemplateGroup[];
  currentGroup?:WpTemplateGroup;
  currentTemplateRows?:WpTemplateRow[];
  checkedAll?:boolean;
  indeterminateAll?:boolean;
} = {};

// eslint-disable-next-line change-detection-strategy/on-push
@Component({
  templateUrl: './wp-import.modal.html',
  styleUrls: ['./wp-import.modal.sass'],
})
export class WpImportModalComponent extends OpModalComponent implements OnInit {
  public wp:WorkPackageResource;

  public projectIdentifier:string|null;

  public wpTypes:TypeResource[] = [];

  public busy = false;

  private _groups:WpTemplateGroup[];

  public get groups() {
    return this._groups;
  }

  set groups(value) {
    tempData.groups = value;
    this._groups = value;
  }

  private _currentGroup:WpTemplateGroup;

  public get currentGroup() {
    return this._currentGroup;
  }

  set currentGroup(value) {
    tempData.currentGroup = value;
    this._currentGroup = value;
  }

  private _currentTemplateRows:WpTemplateRow[] = [];

  public get currentTemplateRows() {
    return this._currentTemplateRows;
  }

  set currentTemplateRows(value) {
    tempData.currentTemplateRows = value;
    this._currentTemplateRows = value;
  }

  private _checkedAll = false;

  public get checkedAll() {
    return this._checkedAll;
  }

  set checkedAll(value) {
    tempData.checkedAll = value;
    this._checkedAll = value;
  }

  private _indeterminateAll = false;

  public get indeterminateAll() {
    return this._indeterminateAll;
  }

  set indeterminateAll(value) {
    tempData.indeterminateAll = value;
    this._indeterminateAll = value;
  }

  public fileAccept = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  public text = {
    button_save: this.I18n.t('js.modals.button_save'),
    confirm: this.I18n.t('js.modals.button_delete'),
    warning: this.I18n.t('js.label_warning'),
    cancel: this.I18n.t('js.button_cancel'),
    close: this.I18n.t('js.close_popup_title'),
    single_text: this.I18n.t('js.modals.destroy_work_package.single_text'),
  };

  constructor(
    readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $state:StateService,
    readonly states:States,
    readonly notificationService:WorkPackageNotificationService,
    readonly backRoutingService:BackRoutingService,
    readonly toastService:ToastService,
    readonly wpCreate:WorkPackageCreateService,
    readonly currentProjectService:CurrentProjectService,
    readonly schemaCache:SchemaCacheService,
    readonly apiV3Service:ApiV3Service,
    readonly halResourceService:HalResourceService,
    readonly wpRelations:WorkPackageRelationsService,
    readonly halEvents:HalEventsService,
    readonly loadingIndicator:LoadingIndicatorService,
  ) {
    super(locals, cdRef, elementRef);

    if (locals.workPackage) {
      this.wp = locals.workPackage as WorkPackageResource;
    }

    this.projectIdentifier = this.currentProjectService.identifier;

    // 读取缓存
    if (tempData.groups) this.groups = tempData.groups;
    if (tempData.currentGroup) this.currentGroup = tempData.currentGroup;
    if (tempData.currentTemplateRows) this.currentTemplateRows = tempData.currentTemplateRows;
    if (tempData.checkedAll) this.checkedAll = tempData.checkedAll;
    if (tempData.indeterminateAll) this.indeterminateAll = tempData.indeterminateAll;
  }

  ngOnInit():void {
    super.ngOnInit();

    if (!this.projectIdentifier) {
      this.showNotice('No project');
      return;
    }

    const typesPath = this.apiV3Service.projects.id(this.projectIdentifier).types.path;
    this.halResourceService.get<CollectionResource<TypeResource>>(typesPath).subscribe((types) => {
      if (!types || types.elements.length === 0) {
        this.showNotice('No types available');
        return;
      }

      this.wpTypes = types.elements;
    });
  }

  validateFile(file:File):boolean {
    if (!(file instanceof File)) {
      this.showNotice('请选择一个文件');
      return false;
    }

    if (file.type !== this.fileAccept) {
      this.showNotice('请选择一个Excel文件，后缀以.xlsx结尾');
      return false;
    }

    return true;
  }

  async onFileChange(event:Event) {
    const input = event.target as HTMLInputElement;

    const file = input.files?.[0];

    input.value = '';

    if (!file) return;

    if (!this.validateFile(file)) return;

    try {
      const data = await this.excel2data(file);

      if (!data || data.length === 0) return;

      this.groups = data;

      this.onGroupClick(this.groups[0]);
    } catch (e) {
      this.showNotice('文件中的数据存在问题');
    }
  }

  validateWpTemplate(wpTemplate:WpTemplate):boolean {
    if (!wpTemplate.id) return false;
    if (!wpTemplate.subject) return false;
    if (!wpTemplate.type) return false;
    return true;
  }

  async excel2data(file:File) {
    const wb = new ExcelJs.Workbook();
    const buffer = await file.arrayBuffer();
    await wb.xlsx.load(buffer);

    const groups:WpTemplateGroup[] = wb.worksheets.map((ws) => {
      const rows = ws.getSheetValues();

      // 去除第一行空行
      rows.shift();

      const firstRow = rows.shift() as string[];

      const headers = firstRow.map((header) => WpImportFieldsMap[header]);

      const values = rows.reduce<WpTemplate[]>(
        (temps, row:string[]) => {
          const temp = row.reduce<WpTemplate>(
            (acc, cell, i) => {
              const header = headers[i];

              if (header) {
                acc[header] = cell.toString();
              }

              return acc;
            },
            {},
          );

          if (this.validateWpTemplate(temp)) {
            temps.push(temp);
          }

          return temps;
        },
        [],
      );

      return {
        key: ws.id,
        name: ws.name,
        values,
      };
    }, []);

    return groups;
  }

  onGroupClick(group:WpTemplateGroup) {
    if (group === this.currentGroup) return;

    this.currentGroup = group;

    this.currentTemplateRows = group.values.map((value) => ({
      value,
      checked: true,
    }));

    this.checkedAll = true;

    this.indeterminateAll = false;

    this.cdRef.detectChanges();
  }

  onRowCheckboxChange(e:Event, row:WpTemplateRow) {
    row.checked = (e.target as HTMLInputElement).checked;

    this.checkedAll = this.currentTemplateRows.every((r) => r.checked);

    this.indeterminateAll = !this.checkedAll && this.currentTemplateRows.some((r) => r.checked);

    this.cdRef.detectChanges();
  }

  onCheckAllChange(e:Event) {
    this.checkedAll = (e.target as HTMLInputElement).checked;

    this.indeterminateAll = false;

    this.currentTemplateRows.forEach((r) => (r.checked = this.checkedAll));

    this.cdRef.detectChanges();
  }

  confirm(e:Event) {
    e.preventDefault();

    if (!this.projectIdentifier) {
      this.showNotice('请选择一个项目');

      return;
    }

    const checkedRows = this.currentTemplateRows.filter((r) => r.checked);

    if (!checkedRows.length) {
      this.showNotice('请至少选择一条数据');

      return;
    }

    const queue = new PromiseTaskQueue();

    checkedRows.forEach((row) => {
      const type = this.wpTypes.find((item) => item.name === row.value.type);

      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      const subject = row.value.subject!;

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const description:any = {
        raw: row.value.description || '',
      };

      // 备注
      const customField6 = row.value.customField6 || '';

      queue.add((lastResult:[WpTemplate, WorkPackageResource][]) => new Promise<[WpTemplate, WorkPackageResource][]>((resolve, reject) => {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
        let parent = this.wp?.$source._links.self;

        if (lastResult && row.value.parent) {
          const parentR = lastResult.find(([rr]) => rr.id === row.value.parent);

          if (parentR) {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
            parent = parentR[1].$source._links.self;
          }
        }

        void this.wpCreate.createNewWorkPackage(this.projectIdentifier, {
          subject,
          customField6,
          _links: {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
            parent,
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
            type: type?.$source._links.self,
          },
        }).then((changeset) => {
          void changeset.buildRequestPayload().then((payload) => {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
            this.apiV3Service.work_packages.post({ ...payload, description }).pipe(
              catchError((error:HttpErrorResponse) => {
                reject(error.message);
                throw new Error(error.message);
              }),
            ).subscribe((work_package) => {
              if (lastResult) {
                resolve([...lastResult, [row.value, work_package]]);
              } else {
                resolve([[row.value, work_package]]);
              }
            });
          });
        }).catch((error) => {
          reject(error);
        });
      }));
    });

    this.busy = true;
    const indicator = this.loadingIndicator.indicator('modal');
    indicator.start();

    queue.start<[WpTemplate, WorkPackageResource][]>()
      .then((results) => {
        // 设置后置于、后置紧跟于关系
        results.forEach(([row, wp], _, arr) => {
          const types = ['heels', 'follows'] as const;

          // eslint-disable-next-line no-restricted-syntax
          for (const type of types) {
            if (!row[type]) continue;

            if (row.id === row[type]) return;

            const wpToRelate = arr.find(([r]) => r.id === row[type]);

            if (!wpToRelate) return;

            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            void this.wpRelations.addCommonRelation(wp.id!, type, wpToRelate[1]!.id!);

            return;
          }
        });
      }).catch((error) => {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
        this.showNotice(error || '导入工作集出错了');
      }).finally(() => {
        this.halEvents.push(
          { _type: 'WorkPackage', id: '1' },
          { eventType: 'created' },
        );
        this.busy = false;
        this.closeMe(e);
        indicator.stop();
      });
  }

  showNotice(message:string) {
    const t = this.toastService.addNotice(message);

    setTimeout(() => {
      this.toastService.remove(t);
    }, 3 * 1000);
  }
}
