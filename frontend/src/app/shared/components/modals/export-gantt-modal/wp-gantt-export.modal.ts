import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import {
  Observable,
  timer,
} from 'rxjs';
import {
  switchMap,
  takeWhile,
} from 'rxjs/operators';
import {
  JobStatusInterface,
} from 'core-app/features/job-status/job-status.interface';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HttpClient, HttpErrorResponse, HttpResponse } from '@angular/common/http';
import { LoadingIndicatorService, withDelayedLoadingIndicator } from 'core-app/core/loading-indicator/loading-indicator.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

/**
 Modal for exporting work packages to different formats. The user may choose from a variety of formats (e.g. PDF and CSV).
 The modal might also be used to only display the progress of an export. This will happen if a link for exporting is provided via the locals.
 */
@Component({
  templateUrl: './wp-gantt-export.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpGanttExportModalComponent extends OpModalComponent implements OnInit {
  public text = {
    title: this.I18n.t('js.label_export'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing'),
    cancelButton: this.I18n.t('js.button_cancel'),
  };

  public queryId:number|null = null;

  public projectId:number|null = null;

  public jobId:string|null = null;

  public isLoading = false;

  public redirectUrl:string|null = null;

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly querySpace:IsolatedQuerySpace,
    readonly cdRef:ChangeDetectorRef,
    readonly httpClient:HttpClient,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly toastService:ToastService,
    readonly currentProject:CurrentProjectService,
    readonly apiV3Service:ApiV3Service,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    const queryId = this.querySpace.query?.value?.id;

    if (queryId) this.queryId = Number(queryId);

    if (this.currentProject.id) this.projectId = Number(this.currentProject.id);
  }

  private listenOnJobStatus() {
    timer(0, 2000)
      .pipe(
        switchMap(() => this.performRequest()),
        takeWhile((response) => !!response.body && this.jobContinuedStatus(response.body), true),
        this.untilDestroyed(),
        withDelayedLoadingIndicator(this.loadingIndicator.getter('modal')),
      ).subscribe(
        (response) => this.onJobResponse(response),
        (error) => this.handleError(error),
      );
  }

  private performRequest():Observable<HttpResponse<JobStatusInterface>> {
    return this
      .httpClient
      .get<JobStatusInterface>(
      this.jobUrl,
      { observe: 'response', responseType: 'json' },
    );
  }

  /**
   * Request the export link and return the job ID to observe
   */
  public requestExport():void {
    this.isLoading = true;

    const body = {
      query_id: this.queryId,
      project_id: this.projectId,
    };

    this
      .httpClient
      .post('/th_queries/export_pdf', body, { observe: 'body', responseType: 'json' })
      .subscribe(
        (json:{ job_id:string }) => {
          this.jobId = json.job_id;
          this.listenOnJobStatus();
        },
        (error) => this.handleError(error),
      );
  }

  private handleError(error:HttpErrorResponse) {
    // There was an error but the status code is actually a 200.
    // If that is the case the response's content-type probably does not match
    // the expected type (json).
    // Currently this happens e.g. when exporting Atom which actually is not an export
    // but rather a feed to follow.
    this.isLoading = false;

    if (error.status === 200 && error.url) {
      window.open(error.url);
    } else {
      this.showError(error);
    }
  }

  private showError(error:HttpErrorResponse) {
    this.toastService.addError(error.message || this.I18n.t('js.error.internal'));
  }

  private get jobUrl():string {
    if (!this.jobId) throw new Error('Job ID is not set.');

    return this.apiV3Service.job_statuses.id(this.jobId).toString();
  }

  /**
 * Determine whether the given status continues the timer
 * @param response
 */
  private jobContinuedStatus(response:JobStatusInterface) {
    return ['in_queue', 'in_process'].includes(response.status);
  }

  private onJobResponse(response:HttpResponse<JobStatusInterface>) {
    const { body } = response;

    if (!body) {
      throw new Error(response as any);
    }

    if (body.payload) {
      if (body.payload.errors && !body.payload.redirect) {
        throw new Error(body.payload.errors);
      }

      if (body.payload.redirect) {
        this.isLoading = false;
        this.redirectUrl = body.payload.redirect;
        window.open(body.payload.redirect, '_blank', 'noopener noreferrer');
      }
    }

    this.cdRef.detectChanges();
  }
}
