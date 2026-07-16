import { Controller } from '@hotwired/stimulus';

const LOCAL_STORAGE_KEY = 'openProject-agent7777PaneCollapsed';
const COLLAPSED_CLASS = 'agent7777-pane-collapsed';
const AVAILABLE_CLASS = 'with-agent7777';

export default class Agent7777PaneToggleController extends Controller<HTMLElement> {
  static targets = ['button', 'main', 'pane'];

  declare readonly buttonTarget:HTMLButtonElement;
  declare readonly hasButtonTarget:boolean;
  declare readonly mainTarget:HTMLElement;
  declare readonly paneTarget:HTMLElement;

  private observer?:MutationObserver;

  connect():void {
    if (!this.hasButtonTarget) {
      return;
    }

    const collapsed = window.OpenProject.guardedLocalStorage(LOCAL_STORAGE_KEY) === 'true';

    this.setExpanded(!collapsed);
    this.syncAvailability();

    this.observer = new MutationObserver(() => this.syncAvailability());
    this.observer.observe(this.mainTarget, { attributes: true, attributeFilter: ['class'] });
  }

  disconnect():void {
    this.observer?.disconnect();
    this.observer = undefined;
  }

  toggle(event:Event):void {
    event.preventDefault();

    if (!this.mainTarget.classList.contains(AVAILABLE_CLASS)) {
      return;
    }

    const expanded = this.buttonTarget.getAttribute('aria-expanded') === 'true';
    this.setExpanded(!expanded);
    window.OpenProject.guardedLocalStorage(LOCAL_STORAGE_KEY, String(expanded));
  }

  private setExpanded(expanded:boolean):void {
    const label = expanded ? this.buttonTarget.dataset.expandedLabel! : this.buttonTarget.dataset.collapsedLabel!;

    this.mainTarget.classList.toggle(COLLAPSED_CLASS, !expanded);
    this.buttonTarget.setAttribute('aria-expanded', String(expanded));
    this.setButtonLabel(label);
    if (expanded) {
      this.paneTarget.removeAttribute('aria-hidden');
    } else {
      this.paneTarget.setAttribute('aria-hidden', 'true');
    }
  }

  private setButtonLabel(label:string):void {
    const labelledBy = this.buttonTarget.getAttribute('aria-labelledby');
    const tooltip = labelledBy && document.getElementById(labelledBy);

    if (tooltip) {
      tooltip.textContent = label;
    }

    this.buttonTarget.removeAttribute('aria-labelledby');
    this.buttonTarget.setAttribute('aria-label', label);
  }

  private syncAvailability():void {
    this.buttonTarget.hidden = !this.mainTarget.classList.contains(AVAILABLE_CLASS);
  }
}
