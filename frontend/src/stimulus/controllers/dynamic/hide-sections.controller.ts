import { Controller } from '@hotwired/stimulus';
import { navigator } from '@hotwired/turbo';

export default class extends Controller {
  static targets = ['section', 'select', 'form'];

  declare readonly sectionTargets:HTMLElement[];

  declare readonly selectTarget:HTMLSelectElement;

  declare readonly formTarget:HTMLFormElement;

  private boundSubmitListener = this.onSubmit.bind(this);

  formTargetConnected(target:HTMLFormElement) {
    target.addEventListener('submit', this.boundSubmitListener);
  }

  formTargetDisconnected(target:HTMLFormElement) {
    target.removeEventListener('submit', this.boundSubmitListener);
  }

  add(event:Event) {
    const selectedValue = (event.target as HTMLSelectElement).value;
    if (!selectedValue) {
      return;
    }

    const section = this.sectionTargets.find((s) => s.dataset.sectionName === selectedValue);
    if (section) {
      section.hidden = false;
    }

    this.toggleOption(selectedValue);
    this.selectTarget.selectedIndex = 0;
  }

  hide(event:MouseEvent) {
    const section = (event.target as HTMLElement).closest('.hide-section') as HTMLElement;
    if (section) {
      section.hidden = true;
    }

    const name = (section as HTMLElement).dataset.name!;
    this.toggleOption(name);
  }

  toggleOption(name:string) {
    const option = Array
      .from(this.selectTarget.options)
      .find((opt:HTMLOptionElement) => opt.value === name);

    if (!option) {
      return;
    }

    option.disabled = !option.disabled;
  }

  // Remove hidden sections on submit
  onSubmit(event:SubmitEvent) {
    if (this.formTarget.dataset.confirmed === 'true' || this.sectionTargets.length === 0) {
      return true;
    }

    const submitter = event.submitter;

    this.formTarget.dataset.confirmed = 'true';
    this.sectionTargets.forEach((section) => {
      if (section.hidden) {
        section.remove();
      }
    });

    event.preventDefault();

    // Turbo disables the clicked submit button before this handler runs.
    // Re-enable it for the second submit after hidden sections were stripped.
    if (submitter instanceof HTMLButtonElement || submitter instanceof HTMLInputElement) {
      submitter.disabled = false;
    }

    navigator.submitForm(this.formTarget, submitter || undefined);
    return false;
  }
}
