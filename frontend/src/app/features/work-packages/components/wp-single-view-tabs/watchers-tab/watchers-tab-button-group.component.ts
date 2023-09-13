import { AfterViewInit, ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageWatchersService } from './wp-watchers.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';

@Component({
  templateUrl: './watchers-tab-button-group.component.html',
  styleUrls: ['./watchers-tab-button-group.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-watchers-tab-button-group',
})
export class WorkPackageWatchersTabButtonGroupComponent implements OnInit, AfterViewInit {
  @Input() addWatchers:(users:any[]) => void;

  @Input() workPackage:WorkPackageResource;

  @Input() loading:boolean;

  private selectedUsers:any[] = [];

  private parentWatching:any[] = [];

  public membersModalOpen = false;

  public project:ProjectResource;

  constructor(
    readonly wpWatchersService:WorkPackageWatchersService,
    readonly notificationService:WorkPackageNotificationService,
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
  ) {}

  ngOnInit():void {
    this.getProject();
  }

  ngAfterViewInit():void {
    this.loadParentWatchers();
  }

  getProject() {
    if (this.currentProject.id) {
      this.apiV3Service.projects.id(this.currentProject.id).get().subscribe((res) => {
        this.project = res;
      });
    }
  }

  get allowSyncParentWatchers() {
    return !!this.workPackage && !!this.workPackage.addWatcher && !!this.workPackage.parent;
  }

  get allowManager() {
    return !!this.project && !!this.project.updateImmediately;
  }

  public loadParentWatchers() {
    if (!this.allowSyncParentWatchers) {
      return;
    }

    this.apiV3Service.work_packages.id(this.workPackage.parent!.id!)
      .requireAndStream()
      .subscribe((wp:WorkPackageResource) => {
        this.wpWatchersService.require(wp)
          .then((watchers:HalResource[]) => {
            this.parentWatching = watchers;
          })
          .catch((error:any) => {
            this.notificationService.showError(error, wp);
          });
      });
  }

  public syncParentWatchers() {
    if (!this.allowSyncParentWatchers) {
      return;
    }
    this.addWatchers(this.parentWatching);
  }

  public openMembersModal() {
    this.membersModalOpen = true;
  }

  public closeMembersModal() {
    this.membersModalOpen = false;
  }

  public handleUsersChange = (users:any[]) => {
    this.selectedUsers = users;
  };

  get membersModalConfirmDisabled() {
    return !this.selectedUsers || this.selectedUsers.length <= 0;
  }

  public addMemberUsers = () => {
    this.closeMembersModal();
    if (!this.selectedUsers || this.selectedUsers.length <= 0) return;
    this.addWatchers([...this.selectedUsers]);
  };
}
