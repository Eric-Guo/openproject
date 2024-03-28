import { States } from 'core-app/core/states/states.service';
import {
  ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
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

type SysTemplateFile = {
  id:number;
  name:string;
  selected:boolean;
  buffer?:ArrayBuffer;
  groups?:WpTemplateGroup[];
};

type SysTemplateFolder = {
  id:number;
  name:string;
  files:SysTemplateFile[];
  selected:boolean;
};

type SysTemplateFileSource = {
  file_id:number;
  file_name:string;
  ext_name:string;
  size:number;
};

type SysTemplateFolderSource = {
  folder_id:number;
  folder_name:string;
  files:SysTemplateFileSource[];
};

type PaymentNode = {
  date:string;
  title:string;
};

type Contract = {
  code:string;
  name:string;
  date:string;
  payment_nodes:PaymentNode[];
};

const tempData:{
  docTitle?:string;
  sysTemplateFolders?:SysTemplateFolder[];
  sysTemplateFiles?:SysTemplateFile[];
  groups?:WpTemplateGroup[];
  currentGroup?:WpTemplateGroup;
  currentTemplateRows?:WpTemplateRow[];
  checkedAll?:boolean;
  indeterminateAll?:boolean;
} = {};

const tempContracts:Record<string, Contract[]> = {};

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

  public _docTitle:string;

  public get docTitle() {
    return this._docTitle;
  }

  set docTitle(value) {
    tempData.docTitle = value;
    this._docTitle = value;
  }

  public _sysTemplateFolders:SysTemplateFolder[] = [];

  public get sysTemplateFolders() {
    return this._sysTemplateFolders;
  }

  set sysTemplateFolders(value) {
    tempData.sysTemplateFolders = value;
    this._sysTemplateFolders = value;
  }

  public _sysTemplateFiles:SysTemplateFile[] = [];

  public get sysTemplateFiles() {
    return this._sysTemplateFiles;
  }

  set sysTemplateFiles(value) {
    tempData.sysTemplateFiles = value;
    this._sysTemplateFiles = value;
  }

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

  public contracts:Contract[] = [];

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
    readonly http:HttpClient,
  ) {
    super(locals, cdRef, elementRef);

    if (locals.workPackage) {
      this.wp = locals.workPackage as WorkPackageResource;
    }

    this.projectIdentifier = currentProjectService.identifier;

    // 读取缓存
    if (tempData.docTitle) this.docTitle = tempData.docTitle;
    if (tempData.sysTemplateFolders) this.sysTemplateFolders = tempData.sysTemplateFolders;
    if (tempData.sysTemplateFiles) this.sysTemplateFiles = tempData.sysTemplateFiles;
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

    this.getSysTemplateFolders();

    this.getContracts();

    this.getWpTypes();
  }

  getWpTypes() {
    if (!this.projectIdentifier) return;

    const typesPath = this.apiV3Service.projects.id(this.projectIdentifier).types.path;
    this.halResourceService.get<CollectionResource<TypeResource>>(typesPath).subscribe((types) => {
      if (!types || types.elements.length === 0) {
        this.showNotice('No types available');
        return;
      }

      this.wpTypes = types.elements;
    });
  }

  getSysTemplateFolders() {
    if (this.sysTemplateFiles && this.sysTemplateFiles.length > 0) return;

    this.http.get('/th_work_packages/templates').subscribe((res) => {
      if (!Array.isArray(res)) return;

      this.sysTemplateFolders = res.map((item:SysTemplateFolderSource) => ({
        id: item.folder_id,
        name: item.folder_name,
        selected: false,
        files: item.files.map((file) => ({
          id: file.file_id,
          name: file.file_name,
          selected: false,
        })),
      }));

      this.cdRef.detectChanges();
    });
  }

  getContracts() {
    if (!this.currentProjectService.id) return;

    const projectId = this.currentProjectService.id;

    if (tempContracts[projectId]) {
      this.contracts = tempContracts[projectId];

      this.cdRef.detectChanges();
      return;
    }

    this.http.get(`/projects/${projectId}/payment_nodes`).subscribe((res:Contract[]) => {
      if (!Array.isArray(res)) return;

      this.contracts = res;
      tempContracts[projectId] = res;

      this.cdRef.detectChanges();
    });
  }

  get canImportPaymentNodes() {
    return this.contracts && this.contracts.length > 0;
  }

  handleClickImportPaymentNodes() {
    if (!this.canImportPaymentNodes) return;

    const group:WpTemplateGroup = {
      key: 'payment_nodes',
      name: '收款节点',
      values: [],
    };

    const getValidDate = (date:string) => {
      if (/^\d{4}-\d{2}-\d{2}/.test(date)) return date.slice(0, 10);
      return '';
    };

    this.contracts.forEach((contract, ci) => {
      group.values.push({
        id: `${ci}`,
        type: '合同',
        subject: contract.name,
        startDate: getValidDate(contract.date),
      });
      contract.payment_nodes.forEach((node, ni) => {
        group.values.push({
          id: `${ci}-${ni}`,
          type: '里程碑',
          subject: `【收款】${node.title}`,
          startDate: getValidDate(node.date),
          parent: `${ci}`,
        });
      });
    });

    this.groups = [group];

    this.docTitle = group.name;

    this.onGroupClick(this.groups[0]);

    this.sysTemplateFiles.forEach((item) => {
      item.selected = false;
    });

    this.cdRef.detectChanges();
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

      this.docTitle = `本地 / ${file.name}`;

      this.onGroupClick(this.groups[0]);

      this.sysTemplateFiles.forEach((item) => {
        item.selected = false;
      });

      this.cdRef.detectChanges();
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

  async excel2data(file:File|ArrayBuffer) {
    const wb = new ExcelJs.Workbook();

    if (file instanceof File) {
      const buffer = await file.arrayBuffer();
      await wb.xlsx.load(buffer);
    } else {
      await wb.xlsx.load(file);
    }

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

      const startDate = row.value.startDate || '';

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
          startDate,
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

  selectSysTemplateFile(sysTemplateFile:SysTemplateFile) {
    if (sysTemplateFile.selected) return;

    sysTemplateFile.selected = true;

    this.sysTemplateFiles.forEach((tf) => {
      if (tf !== sysTemplateFile) tf.selected = false;
    });

    this.cdRef.detectChanges();

    void this.setSysTemplateFileGroups(sysTemplateFile);
  }

  async setSysTemplateFileGroups(sysTemplateFile:SysTemplateFile) {
    this.groups = await this.getSysTemplateFileGroups(sysTemplateFile);

    const selectedFolder = this.sysTemplateFolders.find((f) => f.selected);

    const docTitle = ['系统'];

    if (selectedFolder) {
      docTitle.push(selectedFolder.name);
    }

    docTitle.push(sysTemplateFile.name);

    this.docTitle = docTitle.join(' / ');

    this.onGroupClick(this.groups[0]);
  }

  async getSysTemplateFileGroups(sysTemplateFile:SysTemplateFile) {
    if (sysTemplateFile.groups) return sysTemplateFile.groups;

    if (!sysTemplateFile.buffer) {
      const buffer = await new Promise<ArrayBuffer>((resolve, reject) => {
        this.http.get(`/th_work_packages/templates/${sysTemplateFile.id}/download`, {
          responseType: 'arraybuffer',
        }).pipe(
          catchError((error:HttpErrorResponse) => {
            reject(error);
            throw new Error(error.message);
          }),
        ).subscribe((res) => {
          resolve(res);
        });
      });

      sysTemplateFile.buffer = buffer;
    }

    const groups = await this.excel2data(sysTemplateFile.buffer);

    return groups;
  }

  get downloadUrl() {
    const sysTemplateFile = this.sysTemplateFiles.find((tf) => tf.selected);

    if (!sysTemplateFile) return '';

    return `/th_work_packages/templates/${sysTemplateFile.id}/download`;
  }

  handleSysTemplateFolderChange(e:Event) {
    const target = e.target as HTMLSelectElement;

    const selectedId = Number(target.value);

    let selectedFolder:SysTemplateFolder|undefined;

    this.sysTemplateFolders.forEach((tf) => {
      if (selectedFolder || tf.id !== selectedId) {
        tf.selected = false;
        return;
      }

      selectedFolder = tf;
      tf.selected = true;
    });

    this.sysTemplateFiles.forEach((tf) => {
      tf.selected = false;
    });

    this.sysTemplateFiles = selectedFolder?.files || [];

    this.cdRef.detectChanges();
  }

  handleSysTemplateFileChange(e:Event) {
    const target = e.target as HTMLSelectElement;

    const selectedId = Number(target.value);

    const selectedFile = this.sysTemplateFiles.find((tf) => tf.id === selectedId);

    if (!selectedFile) return;

    this.selectSysTemplateFile(selectedFile);
  }
}
