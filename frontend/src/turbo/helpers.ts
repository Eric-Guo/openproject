import * as Turbo from '@hotwired/turbo';

export namespace TurboHelpers {
  export function showProgressBar() {
    Turbo.session.adapter.formSubmissionStarted?.(undefined as never);
  }

  export function hideProgressBar() {
    Turbo.session.adapter.formSubmissionFinished?.(undefined as never);
  }

  export function scrubScriptElements(element:HTMLElement|DocumentFragment) {
    const cspNonce = document.getElementsByName('csp-nonce')[0]?.getAttribute('content') || '';

    element
      .querySelectorAll('script')
      .forEach((script) => {
        const nonce = script.getAttribute('nonce');

        if (!(nonce && nonce === cspNonce)) {
          console.warn('Removing script element %O because it does not match our nonce', script);
          script.remove();
        }
      });
  }
}
