import {
  AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild,
} from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { NgForm } from '@angular/forms';
import { LoadingIndicator, LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { MembershipResource } from 'core-app/features/hal/resources/membership-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

type GroupMembersItemGroup = {
  type:'group',
  title:string;
  total:number;
  memberIds:string[];
  checkedMemberIds:string[]
  checked:boolean;
  indeterminate:boolean;
};

type GroupMembersItemMember = {
  type:'member';
  member:MembershipResource;
  checked:boolean;
};

@Component({
  templateUrl: './watchers-tab-members.component.html',
  styleUrls: ['./watchers-tab-members.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-watchers-tab-members',
})
export class WorkPackageWatchersTabMembersComponent implements OnInit, AfterViewInit {
  @Input() onUsersChange:(users:unknown[]) => void;

  @ViewChild('filterForm') filterForm:NgForm;

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

  public currentFilter:Record<string, string> = {};

  public selectedCompany = '';

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly cdRef:ChangeDetectorRef,
  ) {}

  ngOnInit():void {
    this.getProject();
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

  getGroupName = (member:MembershipResource) => member.profile?.major?.trim() || '-';

  setCurrentGroupMembers() {
    let currentGroup:GroupMembersItemGroup;
    const admins:GroupMembersItemMember[] = [];
    const groupMembers = (this.currentMembers || []).reduce((groups, member) => {
      const roleIds = member.roles.map((item) => Number(item.id));
      if (roleIds.includes(3)) {
        admins.push({ type: 'member', member, checked: false });
        return groups;
      }
      const last = groups[groups.length - 1];
      const groupTitle = this.getGroupName(member);
      const lastGroupTitle = last && last.type === 'member' ? this.getGroupName(last.member) : '';
      if (groupTitle !== lastGroupTitle) {
        currentGroup = {
          type: 'group',
          title: groupTitle,
          total: 0,
          memberIds: [],
          checkedMemberIds: [],
          checked: false,
          indeterminate: false,
        };
        groups.push(currentGroup);
      }
      currentGroup.total += 1;
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      currentGroup.memberIds.push(member.id!);
      groups.push({ type: 'member', member, checked: false });
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

  handleCurrentGroupMembersChange = () => {
    const users:unknown[] = [];
    this.currentGroupMembers.forEach((item) => {
      if (item.type === 'member' && item.checked) {
        users.push(item.member.principal);
      }
    });
    this.onUsersChange(users);
  };

  handleRowChange = (checked:boolean, member:MembershipResource) => {
    const groupName = this.getGroupName(member);
    this.currentGroupMembers = this.currentGroupMembers.map((item) => {
      if (item.type === 'group' && item.title === groupName) {
        if (checked) {
          // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
          item.checkedMemberIds = Array.from(new Set([...item.checkedMemberIds, member.id!]));
        } else {
          item.checkedMemberIds = item.checkedMemberIds.filter((it) => it !== member.id);
        }
        if (item.checkedMemberIds.length === 0) {
          item.checked = false;
          item.indeterminate = false;
        } else if (item.checkedMemberIds.length >= item.memberIds.length) {
          item.checked = true;
          item.indeterminate = false;
        } else {
          item.checked = false;
          item.indeterminate = true;
        }
      }
      if (item.type === 'member' && item.member.id === member.id) {
        item.checked = checked;
      }
      return item;
    });
    this.handleCurrentGroupMembersChange();
    this.cdRef.detectChanges();
  };

  handleGroupChange = (checked:boolean, name:string) => {
    let currentGroup:GroupMembersItemGroup;
    this.currentGroupMembers = this.currentGroupMembers.map((item) => {
      if (item.type === 'group' && item.title === name) {
        if (checked) {
          item.checkedMemberIds = [...item.memberIds];
        } else {
          item.checkedMemberIds = [];
        }
        if (item.checkedMemberIds.length === 0) {
          item.checked = false;
          item.indeterminate = false;
        } else if (item.checkedMemberIds.length >= item.memberIds.length) {
          item.checked = true;
          item.indeterminate = false;
        } else {
          item.checked = false;
          item.indeterminate = true;
        }
        currentGroup = item;
      }
      if (currentGroup && item.type === 'member' && this.getGroupName(item.member) === currentGroup.title) {
        item.checked = checked;
      }
      return item;
    });
    this.handleCurrentGroupMembersChange();
    this.cdRef.detectChanges();
  };

  get isCheckedAll() {
    return this.currentGroupMembers.every((item) => item.checked);
  }

  get isIndeterminateAll() {
    const checkedLength = this.currentGroupMembers.filter((item) => item.checked).length;
    return checkedLength > 0 && checkedLength < this.currentGroupMembers.length;
  }

  handleCheckAllChange = (checked:boolean) => {
    this.currentGroupMembers = this.currentGroupMembers.map((item) => {
      if (item.type === 'group') {
        if (checked) {
          item.checkedMemberIds = [...item.memberIds];
        } else {
          item.checkedMemberIds = [];
        }
        if (item.checkedMemberIds.length === 0) {
          item.checked = false;
          item.indeterminate = false;
        } else if (item.checkedMemberIds.length >= item.memberIds.length) {
          item.checked = true;
          item.indeterminate = false;
        } else {
          item.checked = false;
          item.indeterminate = true;
        }
      }
      if (item.type === 'member') {
        item.checked = checked;
      }
      return item;
    });
    this.handleCurrentGroupMembersChange();
    this.cdRef.detectChanges();
  };
}
