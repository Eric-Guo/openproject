import { Controller } from '@hotwired/stimulus';

let mountId = 0;

export default class Agent7777Controller extends Controller<HTMLElement> {
  static values = { entrypoint: String };

  declare readonly entrypointValue:string;
  declare readonly hasEntrypointValue:boolean;

  private abortController?:AbortController;

  connect():void {
    if (!this.hasEntrypointValue) {
      return;
    }

    delete this.element.dataset.mountError;
    this.abortController = new AbortController();
    void this.mountAgent(this.abortController.signal);
  }

  disconnect():void {
    this.abortController?.abort();
    this.abortController = undefined;
  }

  private async mountAgent(signal:AbortSignal):Promise<void> {
    try {
      const response = await fetch(this.entrypointValue, { signal, cache: 'no-store' });

      if (!response.ok) {
        throw new Error(`Unable to load Agent7777 entrypoint: ${response.status}`);
      }

      const entrypointUrl = new URL(this.entrypointValue, window.location.href);
      const document = new DOMParser().parseFromString(await response.text(), 'text/html');
      const stylesheet = document.querySelector<HTMLLinkElement>('link[rel="stylesheet"]');
      const script = document.querySelector<HTMLScriptElement>('script[type="module"][src]');

      if (!script?.getAttribute('src')) {
        throw new Error('Unable to find the Agent7777 module entry');
      }

      if (stylesheet?.getAttribute('href') && !documentHasStylesheet(stylesheet.href, entrypointUrl)) {
        const link = window.document.createElement('link');
        link.rel = 'stylesheet';
        link.href = new URL(stylesheet.getAttribute('href')!, entrypointUrl).href;
        window.document.head.append(link);
      }

      if (signal.aborted) {
        return;
      }

      const moduleUrl = new URL(script.getAttribute('src')!, entrypointUrl);
      // Turbo replaces the mount element, so rerun the entry module instead of reusing its cached side effect.
      mountId += 1;
      moduleUrl.searchParams.set('agent7777-mount', String(mountId));
      await import(moduleUrl.href);
    } catch (error) {
      if (signal.aborted) {
        return;
      }

      this.element.dataset.mountError = 'true';
      console.error(error);
    }
  }
}

function documentHasStylesheet(href:string, entrypointUrl:URL):boolean {
  const absoluteHref = new URL(href, entrypointUrl).href;

  return Array.from(window.document.querySelectorAll<HTMLLinkElement>('link[rel="stylesheet"]'))
    .some((link) => link.href === absoluteHref);
}
