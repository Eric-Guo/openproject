import {
  AfterViewInit,
  Component,
  ElementRef,
  OnInit,
  ViewChild,
} from '@angular/core';
import { NgForm } from '@angular/forms';
import * as ExcelJs from 'exceljs';
import { saveAs } from 'file-saver';
import { HttpClient } from '@angular/common/http';
import { catchError } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { LoadingIndicator, LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { MembershipResource } from 'core-app/features/hal/resources/membership-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

type TableRow = {
  name:string;
  email:string;
  roles:string;
  statusName:string;
  company:string;
  department:string;
  position:string;
  mobile:string;
  remark:string;
};

type ImportDatum = {
  name:string;
  email:string;
  roles:string[];
  company:string;
  department:string;
  position:string;
  mobile:string;
  remark:string;
};

// eslint-disable-next-line change-detection-strategy/on-push
@Component({
  selector: 'op-project-members',
  templateUrl: './project-members.component.html',
  styles: ['op-project-members-row { display: contents; }'],
})
export class ProjectMembersComponent implements OnInit, AfterViewInit {
  @ViewChild('filterForm') filterForm:NgForm;

  @ViewChild('addForm') addForm!:ElementRef<HTMLFormElement>;

  @ViewChild('importInput') importInput:ElementRef<HTMLInputElement>;

  public roles:RoleResource[] = [];

  public members:MembershipResource[] = [];

  public currentMembers:MembershipResource[] = [];

  public currentGroupMembers:({ type:'group', title:string; total:number; } | { type:'member', member:MembershipResource })[] = [];

  public project:ProjectResource;

  public indicator:LoadingIndicator;

  public filterFormData = {
    company: '',
    department: '',
    name: '',
    email: '',
    role_id: '',
  };

  public addFormData = {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    users: [] as any[],
    roleIds: '',
  };

  public currentFilter:Record<string, string> = {};

  public currentAction:'add'|'filter'|null = null;

  public selectedCompany = '';

  public importData:ImportDatum[] = [];

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
    readonly i18n:I18nService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly toastService:ToastService,
    readonly httpClient:HttpClient,
  ) {}

  ngOnInit():void {
    this.getProject();
    this.getRoles();
  }

  ngAfterViewInit():void {
    this.indicator = this.loadingIndicator.indicator('members-module');
    this.getMembers();
    this.filterForm.valueChanges?.subscribe((value:typeof this.filterFormData) => {
      if (value.company !== this.selectedCompany) {
        this.selectedCompany = value.company;
        this.filterFormData.department = '';
      }
    });
  }

  getRoles() {
    const filters = new ApiV3FilterBuilder();
    filters.add('unit', '=', ['project']);
    this.apiV3Service.roles.filtered(filters, { sortBy: JSON.stringify([['position', 'desc']]) }).get().subscribe((res) => {
      this.roles = res.elements;
    });
  }

  getMembers = () => {
    if (!this.currentProject.id) throw new Error('projectId不能为空');
    this.indicator.start();
    const filters = new ApiV3FilterBuilder();
    filters.add('project', '=', [this.currentProject.id]);
    this.apiV3Service.memberships.filtered(filters, { pageSize: '-1' }).get().subscribe((res) => {
      this.indicator.delayedStop(150);
      this.members = res.elements;
      this.setCurrentMembers();
    });
  };

  getProject() {
    if (this.currentProject.id) {
      this.apiV3Service.projects.id(this.currentProject.id).get().subscribe((res) => {
        this.project = res;
      });
    }
  }

  setCurrentMembers() {
    this.currentMembers = this.members.filter((member) => {
      if (this.currentFilter.email && !member.email.includes(this.currentFilter.email)) return false;
      if (this.currentFilter.name && !member.name.includes(this.currentFilter.name)) return false;
      if (this.currentFilter.role_id && !member.roles.some((role) => Number(role.id) === Number(this.currentFilter.role_id))) return false;
      if (this.currentFilter.company) {
        if (!member.profile) return false;
        if (this.currentFilter.company !== member.profile.company) return false;
        if (this.currentFilter.department && this.currentFilter.department !== member.profile.department) return false;
      }
      return true;
    }).sort((a, b) => {
      if (!b.profile) return -1;
      if (!a.profile) return 1;
      if (!b.profile.company) return -1;
      if (!a.profile.company) return 1;
      const companyAB = a.profile.company.localeCompare(b.profile.company);
      if (companyAB !== 0) return companyAB;
      if (!b.profile.department) return -1;
      if (!a.profile.department) return 1;
      const departmentAB = a.profile.department.localeCompare(b.profile.department);
      return departmentAB;
    });
    this.setCurrentGroupMembers();
  }

  get allowAddMember() {
    return !!this.project && !!this.project.updateImmediately;
  }

  get autoCompleterUrl() {
    if (!this.currentProject.identifier) return null;
    return `/projects/${this.currentProject.identifier}/members/autocomplete_for_member.json`;
  }

  get addMemberUrl() {
    if (!this.currentProject.identifier) return null;
    return `/projects/${this.currentProject.identifier}/members`;
  }

  handleImport = () => {
    if (!this.importInput.nativeElement) return;
    this.importInput.nativeElement.click();
  };

  handleExport = async () => {
    const wb = new ExcelJs.Workbook();
    const ws = wb.addWorksheet('sheet1');
    ws.columns = [
      { header: '名称', key: 'name', width: 10 },
      { header: '电子邮件**', key: 'email', width: 30 },
      { header: '角色**', key: 'roles', width: 20 },
      { header: '状态', key: 'statusName', width: 20 },
      { header: '公司*', key: 'company', width: 20 },
      { header: '部门*', key: 'department', width: 20 },
      { header: '职位*', key: 'position', width: 20 },
      { header: '手机号*', key: 'mobile', width: 20 },
      { header: '备注*', key: 'remark', width: 20 },
    ];
    const roleNames = this.roles.map((item) => item.name);
    ws.addRow({ name: `带两个*号项：表示必填项；带一个*号项：表示选填项；无*号项：表示不填项；角色值：${roleNames.join('、')}` });
    ws.mergeCells(2, 1, 2, ws.columns.length);
    ws.getCell('A2').alignment = {
      vertical: 'middle',
      horizontal: 'center',
    };
    ws.getCell('A2').font = {
      color: { argb: 'FFFF0000' },
      size: 9,
    };
    this.currentMembers.forEach((member) => {
      ws.addRow({
        name: member.name,
        email: member.email,
        roles: member.roles.map((item) => item.name).join(','),
        statusName: member.statusName,
        company: member.profile?.company || '',
        department: member.profile?.department || '',
        position: member.profile?.position || '',
        remark: member.profile?.remark || '',
      });
    });
    const buf = await wb.xlsx.writeBuffer();
    saveAs(new Blob([buf]), `${this.currentProject?.name || '项目'}-成员列表.xlsx`);
  };

  openAction(name:Exclude<typeof this.currentAction, null>) {
    this.currentAction = name;
  }

  closeAction() {
    this.currentAction = null;
  }

  get companies() {
    if (!this.members) return [];
    const companies:Set<string> = new Set();
    this.members.forEach((member) => {
      if (member.profile && member.profile.company) {
        companies.add(member.profile.company.trim());
      }
    });
    return [...companies];
  }

  get departments() {
    if (!this.members || !this.selectedCompany) return [];
    const departments:Set<string> = new Set();
    this.members.forEach((member) => {
      if (member.profile && member.profile.department && member.profile.company === this.selectedCompany) {
        departments.add(member.profile.department.trim());
      }
    });
    return [...departments];
  }

  setCurrentGroupMembers() {
    let group:{ type:'group'; title:string; total:number; };
    this.currentGroupMembers = (this.currentMembers || []).reduce((groups, member) => {
      const last = groups[groups.length - 1];
      const groupTitle = `${member.profile?.company?.trim() || ''} - ${member.profile?.department?.trim() || ''}`;
      const lastGroupTitle = last && last.type === 'member' ? `${last.member.profile?.company?.trim() || ''} - ${last.member.profile?.department?.trim() || ''}` : '';
      if (groupTitle !== lastGroupTitle) {
        group = { type: 'group', title: groupTitle, total: 0 };
        groups.push(group);
      }
      group.total += 1;
      groups.push({ type: 'member', member });
      return groups;
    }, [] as typeof this.currentGroupMembers);
  }

  handleFilterSubmit(form:NgForm) {
    if (!form.valid) return;
    this.currentFilter = { ...this.filterFormData };
    this.setCurrentMembers();
  }

  handleFilterReset() {
    this.currentFilter = {};
    this.setCurrentMembers();
  }

  async handleImportInputChange() {
    const input = this.importInput.nativeElement;
    if (!input || !input.value || !input.files) return;
    try {
      const file = input.files[0];
      input.value = '';
      if (file.type !== 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') throw new Error('上传的文件格式不正确');
      const buf = await file.arrayBuffer();
      const wb = new ExcelJs.Workbook();
      await wb.xlsx.load(buf);
      const ws = wb.getWorksheet(1);
      if (!ws) throw new Error('未找到有效的sheet');
      const rows:TableRow[] = [];
      const emailCounts:Record<string, number> = {};
      ws.eachRow((row, rowNumber) => {
        if (rowNumber > 2) {
          const rowData = {
            name: row.getCell(1).text,
            email: row.getCell(2).text,
            roles: row.getCell(3).text,
            statusName: row.getCell(4).text,
            company: row.getCell(5).text,
            department: row.getCell(6).text,
            position: row.getCell(7).text,
            mobile: row.getCell(8).text,
            remark: row.getCell(9).text,
          };
          if (!/^[A-Za-z0-9\u4e00-\u9fa5]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$/.test(rowData.email)) return;
          if (!emailCounts[rowData.email]) emailCounts[rowData.email] = 0;
          emailCounts[rowData.email] += 1;
          if (emailCounts[rowData.email] > 1) throw new Error(`邮箱${rowData.email}重复`);
          rows.push(rowData);
        }
      });
      if (rows.length === 0) throw new Error('未找到人员信息');
      await this.setImportData(rows);
    } catch (err) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
      this.toastService.addError(err.message);
    }
  }

  addMember = async (userId:string, datum:ImportDatum) => {
    const url = this.addMemberUrl;
    if (!url) throw new Error('未找到创建成员的接口');
    const csrfParamMeta = document.querySelector<HTMLMetaElement>('meta[name="csrf-param"]');
    const csrfTokenMeta = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]');
    if (!csrfParamMeta || !csrfTokenMeta) throw new Error('csrf token 不存在');
    const formData = new FormData();
    formData.append('utf8', '✓');
    formData.append(csrfParamMeta.content, csrfTokenMeta.content);
    formData.append('member[user_ids][]', userId);
    formData.append('member[role_ids][]', datum.roles.join(','));
    formData.append('member[profile_attributes][company]', datum.company);
    formData.append('member[profile_attributes][department]', datum.department);
    formData.append('member[profile_attributes][position]', datum.position);
    formData.append('member[profile_attributes][remark]', datum.remark);
    formData.append('button', '');
    await new Promise((resolve, reject) => {
      this.httpClient.post(url, formData).pipe(
        catchError((error) => {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
          reject(error.error);
          throw error;
        }),
      ).subscribe((res) => {
        resolve(res);
      });
    });
  };

  updateMember = async (member:MembershipResource, formData:ImportDatum) => {
    const profile = {
      company: formData.company,
      department: formData.department,
      position: formData.position,
      mobile: formData.mobile,
      remark: formData.remark,
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const body:Record<string, any> = {};
    const roles = this.roles.filter((item) => formData.roles.includes(item.id as string)).map((item) => item.$link);
    if (roles.length > 0) body.roles = roles;
    await member.updateImmediately({
      profile,
      roles,
    });
  };

  setImportData = async (rows:TableRow[]) => {
    try {
      this.indicator.start();
      await Promise.all(rows.map(async (row) => {
        const roles = row.roles.split(',');
        const datum:ImportDatum = {
          name: row.name,
          email: row.email,
          roles: this.roles.filter((role) => roles.includes(role.name)).map((role) => role.id as string),
          company: row.company,
          department: row.department,
          position: row.position,
          mobile: row.mobile,
          remark: row.remark,
        };
        const member = this.members.find((item) => item.email === datum.email);
        if (member) {
          await this.updateMember(member, datum);
        } else {
          if (!this.autoCompleterUrl) return;
          const url = this.autoCompleterUrl;
          const result = await new Promise<{ id:string; name:string; }[]>((resolve) => {
            this.httpClient.get(url, {
              params: {
                q: datum.email,
              },
            }).subscribe((res:{ id:string; name:string; }[]) => {
              resolve(res);
            });
          });
          if (!Array.isArray(result) || result.length === 0) return;
          const user = result[0];
          await this.addMember(user.id, datum);
        }
      }));
      this.toastService.addSuccess('人员信息更新成功');
      setTimeout(() => {
        this.getMembers();
      }, 50);
    } catch (err) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
      this.toastService.addError(err.message);
    } finally {
      this.indicator.stop();
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  handleAddFormDataChange = (field:string, e:any) => {
    if (field === 'users') {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      this.addFormData.users = e as any[];
    }
    if (field === 'roleIds') {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
      this.addFormData.roleIds = e.target.value;
    }
  };

  handleAddSubmit = async () => {
    try {
      this.indicator.start();
      const formData = new FormData(this.addForm.nativeElement);
      const userIds = formData.get('member[user_ids][]');
      const roleIds = formData.get('member[role_ids][]');
      if (!userIds) throw new Error('请选择一个用户');
      if (!roleIds) throw new Error('请选择一个角色');
      const url = this.addMemberUrl;
      if (!url) throw new Error('未找到创建成员的接口');
      const csrfParamMeta = document.querySelector<HTMLMetaElement>('meta[name="csrf-param"]');
      const csrfTokenMeta = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]');
      if (!csrfParamMeta || !csrfTokenMeta) throw new Error('csrf token 不存在');
      formData.append('utf8', '✓');
      formData.append(csrfParamMeta.content, csrfTokenMeta.content);
      formData.append('button', '');
      await new Promise((resolve, reject) => {
        this.httpClient.post(url, formData).pipe(
          catchError((error) => {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            reject(error.error);
            throw error;
          }),
        ).subscribe((res) => {
          resolve(res);
        });
      });
      this.addFormData.users = [];
      this.addFormData.roleIds = this.roles[0].id as string;
      setTimeout(() => {
        this.getMembers();
      }, 50);
    } catch (err) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
      this.toastService.addError(err.message);
    } finally {
      this.indicator.stop();
    }
  };
}
