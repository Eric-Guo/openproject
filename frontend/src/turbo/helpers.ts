import * as Turbo from '@hotwired/turbo';

function hasProgressBar(adapter:Turbo.Adapter):adapter is Turbo.BrowserAdapter {
  return 'progressBar' in adapter;
}

export namespace TurboHelpers {
  export function showProgressBar() {
    const adapter = Turbo.navigator.delegate.adapter;
    if (hasProgressBar(adapter)) {
      adapter.progressBar.show();
    }
  }

  export function hideProgressBar() {
    const adapter = Turbo.navigator.delegate.adapter;
    if (hasProgressBar(adapter)) {
      adapter.progressBar.hide();
    }
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
