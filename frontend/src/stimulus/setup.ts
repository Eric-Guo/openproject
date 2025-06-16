import { Application } from '@hotwired/stimulus';
import { environment } from '../environments/environment';
import { OpApplicationController } from './controllers/op-application.controller';
import MainMenuController from './controllers/dynamic/menus/main.controller';
import OpDisableWhenCheckedController from './controllers/disable-when-checked.controller';
import PrintController from './controllers/print.controller';
import RefreshOnFormChangesController from './controllers/refresh-on-form-changes.controller';
import FormPreviewController from './controllers/form-preview.controller';
import AsyncDialogController from './controllers/async-dialog.controller';
import PollForChangesController from './controllers/poll-for-changes.controller';
import TableHighlightingController from './controllers/table-highlighting.controller';
import OpShowWhenCheckedController from './controllers/show-when-checked.controller';
import OpShowWhenValueSelectedController from './controllers/show-when-value-selected.controller';
import FlashController from './controllers/flash.controller';
import OpProjectsZenModeController from './controllers/dynamic/projects/zen-mode.controller';
import PasswordConfirmationDialogController from './controllers/password-confirmation-dialog.controller';
import PreviewController from './controllers/dynamic/work-packages/date-picker/preview.controller';
import KeepScrollPositionController from './controllers/keep-scroll-position.controller';
import PatternInputController from './controllers/pattern-input.controller';
import HoverCardTriggerController from './controllers/hover-card-trigger.controller';
import ScrollIntoViewController from './controllers/scroll-into-view.controller';
import CkeditorFocusController from './controllers/ckeditor-focus.controller';

declare global {
  interface Window {
    Stimulus:Application;
  }
}

const instance = Application.start();
window.Stimulus = instance;

instance.debug = !environment.production;
instance.handleError = (error, message, detail) => {
  console.warn(error, message, detail);
};

instance.register('async-dialog', AsyncDialogController);
instance.register('disable-when-checked', OpDisableWhenCheckedController);
instance.register('flash', FlashController);
instance.register('menus--main', MainMenuController);
instance.register('password-confirmation-dialog', PasswordConfirmationDialogController);
instance.register('poll-for-changes', PollForChangesController);
instance.register('print', PrintController);
instance.register('refresh-on-form-changes', RefreshOnFormChangesController);
instance.register('form-preview', FormPreviewController);
instance.register('hover-card-trigger', HoverCardTriggerController);
instance.register('show-when-checked', OpShowWhenCheckedController);
instance.register('show-when-value-selected', OpShowWhenValueSelectedController);
instance.register('table-highlighting', TableHighlightingController);
instance.register('projects-zen-mode', OpProjectsZenModeController);
instance.register('work-packages--date-picker--preview', PreviewController);
instance.register('keep-scroll-position', KeepScrollPositionController);
instance.register('pattern-input', PatternInputController);
instance.register('scroll-into-view', ScrollIntoViewController);
instance.register('ckeditor-focus', CkeditorFocusController);

// Application controller must be registered last, as it tries to automatically load other controllers
// not yet registered.
instance.register('application', OpApplicationController);
