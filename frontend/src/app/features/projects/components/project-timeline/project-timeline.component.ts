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

  loadingUrl = 'https://ith-workspace.thape.com.cn/ppm/loading';

  errorUrl = 'https://ith-workspace.thape.com.cn/ppm/error';

  detailUrl = 'https://ith-workspace.thape.com.cn/ppm/projects/:code/timeline';

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
    readonly sanitizer:DomSanitizer,
    readonly i18n:I18nService,
  ) {
    this.setLoadingUrl('正在获取项目信息...');
  }

  ngOnInit() {
    this.title = this.i18n.t('js.label_project_timeline_plural');
    if (this.currentProject.id) {
      this.apiV3Service.projects.id(this.currentProject.id).get().subscribe(
        (data) => {
          this.project = data;
          this.setDetailUrl();
        },
        () => {
          this.project = null;
          this.setErrorUrl('错误提示', '项目信息获取失败');
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

  setLoadingUrl(tip = '') {
    const urlSearch = new URLSearchParams({ tip });
    this.url = this.sanitizer.bypassSecurityTrustResourceUrl(`${this.loadingUrl}?${urlSearch.toString()}`);
  }

  setErrorUrl(title = '', message = '') {
    const urlSearch = new URLSearchParams({ title, message });
    this.url = this.sanitizer.bypassSecurityTrustResourceUrl(`${this.errorUrl}?${urlSearch.toString()}`);
  }

  setDetailUrl() {
    if (this.project && this.project.profile && this.project.profile.code) {
      const link = this.detailUrl.replace(':code', this.project.profile.code);;
      this.url = this.sanitizer.bypassSecurityTrustResourceUrl(link);
    } else {
      this.setErrorUrl('错误提示', '该项目的天华项目编号未填写，请到 项目设置->信息 中填写');
    }
  }
}
