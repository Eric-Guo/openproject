import {
  Component, Input,
} from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { MembershipResource } from 'core-app/features/hal/resources/membership-resource';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

// eslint-disable-next-line change-detection-strategy/on-push
@Component({
  selector: 'op-project-members-row',
  templateUrl: './project-members-row.component.html',
  styles: ['op-project-members-row { display: table-row; }'],
})
export class ProjectMembersRowComponent {
  @Input() roles:RoleResource[] = [];

  @Input() member:MembershipResource;

  @Input() reloadMembers:() => void;

  @Input() isProjectAdmin:boolean;

  public invitedTip = '用户已被邀请，正在等待注册';

  public editing = false;

  public formData = {
    name: '',
    roles: [] as string[],
    company: '',
    department: '',
    position: '',
    major: '',
    mobile: '',
    remark: '',
  };

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly i18n:I18nService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly toastService:ToastService,
  ) {}

  setFormData() {
    this.formData.name = this.member.profile?.name || this.principal.name || '';
    this.formData.roles = this.member.roles.map((item) => item.id as string);
    this.formData.company = this.member.profile?.company || '';
    this.formData.department = this.member.profile?.department || '';
    this.formData.position = this.member.profile?.position || '';
    this.formData.major = this.member.profile?.major || '';
    this.formData.mobile = this.member.profile?.mobile || '';
    this.formData.remark = this.member.profile?.remark || '';
  }

  handleEdit() {
    this.editing = true;
    this.setFormData();
  }

  handleCancel() {
    this.editing = false;
  }

  handleConfirm() {
    void this.updateMember();
  }

  handleRoleChange(e:InputEvent, roleId:string) {
    const target = e.target as HTMLInputElement;
    if (target.checked) {
      this.formData.roles = Array.from(new Set([...this.formData.roles, roleId]));
    } else {
      this.formData.roles = this.formData.roles.filter((item) => item !== roleId);
    }
  }

  updateMember = async () => {
    const indicator = this.loadingIndicator.indicator('members-module');
    indicator.start();
    try {
      const profile = {
        name: this.formData.name,
        company: this.formData.company,
        department: this.formData.department,
        position: this.formData.position,
        major: this.formData.major,
        mobile: this.formData.mobile,
        remark: this.formData.remark,
      };
      const roles = this.roles.filter((item) => this.formData.roles.includes(item.id as string));
      if (roles.length === 0) throw new Error('角色需要进行分配');
      await this.member.updateImmediately({
        profile,
        roles: roles.map((role) => role.$link),
      });
      this.reloadMembers();
      this.editing = false;
      this.toastService.addSuccess('更新成功');
    } catch (err) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
      this.toastService.addError(err.message);
    } finally {
      indicator.stop();
    }
  };

  removeMember = async () => {
    // eslint-disable-next-line no-restricted-globals, no-alert
    if (confirm('您要移除部分或全部权限，并且可能无法在此后编辑这个项目。您确定要继续吗？')) {
      const indicator = this.loadingIndicator.indicator('members-module');
      indicator.start();
      try {
        await this.member.delete();
        this.reloadMembers();
        this.toastService.addSuccess('删除成功');
      } catch (err) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
        this.toastService.addError(err.message);
      } finally {
        indicator.stop();
      }
    }
  };

  get principal() {
    return this.member.principal;
  }

  get name() {
    return this.member.profile?.name || this.member.principal.name;
  }

  get memberRoles() {
    return this.member.roles.map((item) => item.name).join(',');
  }

  get email() {
    return this.member.email;
  }

  get mailTo() {
    if (!this.email) return '#';
    return `mailto:${this.email}`;
  }

  get status() {
    return this.member.status;
  }

  get statusName() {
    return this.member.statusName;
  }

  get isInvited() {
    return this.status === 'invited';
  }

  get company() {
    return this.member.profile?.company;
  }

  get department() {
    return this.member.profile?.department;
  }

  get position() {
    return this.member.profile?.position;
  }

  get major() {
    return this.member.profile?.major;
  }

  get mobile() {
    return this.member.profile?.mobile;
  }

  get remark() {
    return this.member.profile?.remark;
  }

  get canUpdate() {
    return !!this.member.updateImmediately;
  }

  get canDelete() {
    return !!this.member.delete;
  }
}
