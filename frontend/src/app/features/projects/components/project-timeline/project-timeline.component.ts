import {
  AfterViewInit,
  Component,
  ElementRef,
  OnInit,
  ViewChild,
} from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';

@Component({
  selector: 'op-project-timeline',
  templateUrl: './project-timeline.component.html',
})
export class ProjectTimelineComponent implements AfterViewInit, OnInit {
  @ViewChild('iframe', { static: true }) iframeRef:ElementRef<HTMLIFrameElement>;

  public project:ProjectResource|null = null;

  public url:SafeResourceUrl|null = null;

  public title:string|null = null;

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
    readonly sanitizer:DomSanitizer,
    readonly i18n:I18nService,
  ) {}

  ngOnInit() {
    this.title = this.i18n.t('js.label_project_timeline_plural');
    if (this.currentProject.id) {
      this.apiV3Service.projects.id(this.currentProject.id).get().subscribe(
        (data) => {
          this.project = data;
          this.setUrl();
        },
        () => {
          this.project = null;
        },
      );
    }
  }

  ngAfterViewInit() {
    this.resetIFrameHeight();
    window.addEventListener('resize', () => {
      this.resetIFrameHeight();
    });
  }

  resetIFrameHeight() {
    if (this.iframeRef) {
      const clientHeight = document.documentElement.clientHeight;
      const rect = this.iframeRef.nativeElement.getBoundingClientRect();
      const top = rect.top;
      const bottom = 10;
      const height = clientHeight - top - bottom;
      this.iframeRef.nativeElement.height = height.toString();
    }
  }

  setUrl() {
    if (this.project && this.project.profile && this.project.profile.code) {
      const link = `https://ith-workspace.thape.com.cn/ppm/projects/${this.project.profile.code}/timeline`;
      this.url = this.sanitizer.bypassSecurityTrustResourceUrl(link);
    } else {
      this.url = null;
    }
  }
}
