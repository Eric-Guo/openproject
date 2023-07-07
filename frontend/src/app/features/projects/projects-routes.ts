import { Ng2StateDeclaration, UIRouter } from '@uirouter/angular';
import { ProjectsComponent } from 'core-app/features/projects/components/projects/projects.component';
import { NewProjectComponent } from 'core-app/features/projects/components/new-project/new-project.component';
import { CopyProjectComponent } from 'core-app/features/projects/components/copy-project/copy-project.component';
import { ProjectTimelineComponent } from 'core-app/features/projects/components/project-timeline/project-timeline.component';
import { ProjectMembersComponent } from 'core-app/features/projects/components/members/project-members.component';

export const PROJECTS_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'project_settings',
    parent: 'optional_project',
    url: '/settings/general/',
    component: ProjectsComponent,
  },
  {
    name: 'project_copy',
    parent: 'optional_project',
    url: '/copy',
    component: CopyProjectComponent,
  },
  {
    name: 'new_project',
    url: '/projects/new?parent_id',
    component: NewProjectComponent,
  },
  {
    name: 'project_timeline',
    parent: 'optional_project',
    url: '/project_timeline',
    component: ProjectTimelineComponent,
  },
  {
    name: 'project_members',
    parent: 'optional_project',
    url: '/members',
    component: ProjectMembersComponent,
  },
];

export function uiRouterProjectsConfiguration(uiRouter:UIRouter) {
  // Ensure projects/ are being redirected correctly
  // cf., https://community.openproject.com/wp/29754
  uiRouter.urlService.rules
    .when(
      new RegExp('^/projects/(.*)/settings/general$'),
      (match:string[]) => `/projects/${match[1]}/settings/general/`,
    );
}
