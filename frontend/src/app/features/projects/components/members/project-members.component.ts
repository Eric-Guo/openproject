import {
  AfterViewInit,
  ChangeDetectorRef,
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
  major:string;
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
  major:string;
  mobile:string;
  remark:string;
};

type GroupMembersItemGroup = {
  type:'group',
  title:string;
  total:number;
};

type GroupMembersItemMember = {
  type:'member';
  member:MembershipResource;
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

  public currentGroupMembers:(GroupMembersItemGroup | GroupMembersItemMember)[] = [];

  public project:ProjectResource;

  public indicator:LoadingIndicator;

  public filterFormData = {
    company: '',
    department: '',
    major: '',
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
    readonly cdRef:ChangeDetectorRef,
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
      if (this.currentFilter.major) {
        if (!member.profile) return false;
        if (this.currentFilter.major && this.currentFilter.major !== member.profile.major) return false;
      }
      return true;
    }).sort((a, b) => {
      if (!b.profile) return -1;
      if (!a.profile) return 1;
      if (!b.profile.major) return -1;
      if (!a.profile.major) return 1;
      return a.profile.major.localeCompare(b.profile.major);
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

  get isProjectAdmin() {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return !!this.project && !!this.project.updateImmediately && !!this.project.updateImmediately.href;
  }

  handleImport = () => {
    if (!this.importInput.nativeElement) return;
    this.importInput.nativeElement.click();
  };

  exportSheet = async (rows:{
    name:string;
    email:string;
    roles:string;
    statusName:string;
    company:string;
    department:string;
    position:string;
    major:string;
    mobile:string;
    remark:string;
  }[], filename:string) => {
    const roleNames = this.roles.map((item) => item.name);
    const wb = new ExcelJs.Workbook();
    const ws = wb.addWorksheet('sheet1');
    ws.columns = [
      { header: '名称', key: 'name', width: 10 },
      { header: '电子邮件（必填）', key: 'email', width: 30 },
      { header: '角色（必填）', key: 'roles', width: 20 },
      { header: '状态', key: 'statusName', width: 20 },
      { header: '公司', key: 'company', width: 20 },
      { header: '部门', key: 'department', width: 20 },
      { header: '职位', key: 'position', width: 20 },
      { header: '专业', key: 'major', width: 20 },
      { header: '手机号', key: 'mobile', width: 20 },
      { header: '备注', key: 'remark', width: 20 },
    ];
    ws.getRow(1).height = 20;
    ws.getRow(1).alignment = {
      vertical: 'middle',
      horizontal: 'center',
    };
    ws.getRow(1).font = {
      size: 12,
      bold: true,
    };
    ws.addRow({
      name: [
        `角色值：${roleNames.join('、')}`,
        '必填项：电子邮件、角色',
        '选填项：名称、公司、部门、职位、专业、手机号',
        '一行一条数据，不支持合并表格数据，否则系统无法正确读取',
      ].join('\n'),
    });
    ws.getRow(2).height = 60;
    ws.mergeCells(2, 1, 2, ws.columns.length);
    ws.getCell('A2').alignment = {
      vertical: 'middle',
      horizontal: 'left',
      wrapText: true,
    };
    ws.getCell('A2').font = {
      color: { argb: 'FF203680' },
      size: 10,
    };

    rows.forEach((row) => {
      ws.addRow(row);
    });

    const buf = await wb.xlsx.writeBuffer();
    saveAs(new Blob([buf]), `${filename}.xlsx`);
  };

  handleExport = async () => {
    const rows = this.currentMembers.map((member) => ({
      name: member.name,
      email: member.email,
      roles: member.roles.map((item) => item.name).join(','),
      statusName: member.statusName,
      company: member.profile?.company || '',
      department: member.profile?.department || '',
      position: member.profile?.position || '',
      major: member.profile?.major || '',
      mobile: member.profile?.mobile || '',
      remark: member.profile?.remark || '',
    }));

    await this.exportSheet(rows, `${this.currentProject?.name || '项目'}-成员列表`);
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

  get majors() {
    if (!this.members) return [];
    const majors:Set<string> = new Set();
    this.members.forEach((member) => {
      if (member.profile && member.profile.major) {
        majors.add(member.profile.major.trim());
      }
    });
    return [...majors];
  }

  setCurrentGroupMembers() {
    let currentGroup:GroupMembersItemGroup;
    const admins:GroupMembersItemMember[] = [];
    const getGroupTitle = (profile?:MembershipResource['profile']) => profile?.major?.trim() || '-';
    const groupMembers = (this.currentMembers || []).reduce((groups, member) => {
      const roleIds = member.roles.map((item) => Number(item.id));
      if (roleIds.includes(3)) {
        admins.push({ type: 'member', member });
        return groups;
      }
      const last = groups[groups.length - 1];
      const groupTitle = getGroupTitle(member.profile);
      const lastGroupTitle = last && last.type === 'member' ? getGroupTitle(last.member.profile) : '';
      if (groupTitle !== lastGroupTitle) {
        currentGroup = {
          type: 'group',
          title: groupTitle,
          total: 0,
        };
        groups.push(currentGroup);
      }
      currentGroup.total += 1;
      groups.push({ type: 'member', member });
      return groups;
    }, [] as typeof this.currentGroupMembers);
    this.currentGroupMembers = [...admins, ...groupMembers];
    this.cdRef.detectChanges();
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
      const parseCell = (cell:ExcelJs.Cell) => cell.toCsvString().trim().replace(/(^("|')[\s]*)|([\s]*("|')$)/g, '');
      ws.eachRow((row, rowNumber) => {
        if (rowNumber > 2) {
          const rowData = {
            name: parseCell(row.getCell(1)),
            email: parseCell(row.getCell(2)).replace(/^((mailto:)|(https?:\/\/))/, ''),
            roles: parseCell(row.getCell(3)),
            statusName: parseCell(row.getCell(4)),
            company: parseCell(row.getCell(5)),
            department: parseCell(row.getCell(6)),
            position: parseCell(row.getCell(7)),
            major: parseCell(row.getCell(7)),
            mobile: parseCell(row.getCell(8)),
            remark: parseCell(row.getCell(9)),
          };
          if (!/^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/.test(rowData.email)) return;
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
    formData.append('member[profile_attributes][name]', datum.name);
    formData.append('member[profile_attributes][company]', datum.company);
    formData.append('member[profile_attributes][department]', datum.department);
    formData.append('member[profile_attributes][position]', datum.position);
    formData.append('member[profile_attributes][major]', datum.major);
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
      name: formData.name,
      company: formData.company,
      department: formData.department,
      position: formData.position,
      major: formData.major,
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
          major: row.major,
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
    } catch (err) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
      this.toastService.addError(err.message);
    } finally {
      this.indicator.stop();
      setTimeout(() => {
        this.getMembers();
      }, 50);
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

  handleDownloadTemplate = async () => {
    await this.exportSheet([], '项目成员列表模板');
  };
}
