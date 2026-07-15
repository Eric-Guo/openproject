const agentRoot = document.getElementById('oc-agent');

if (agentRoot instanceof HTMLElement) {
  const entrypoint = agentRoot.dataset.entrypoint;

  if (entrypoint) {
    void mountAgent(agentRoot, entrypoint);
  }
}

async function mountAgent(agentRoot:HTMLElement, entrypoint:string):Promise<void> {
  try {
    const response = await fetch(entrypoint);

    if (!response.ok) {
      throw new Error(`Unable to load Agent7777 entrypoint: ${response.status}`);
    }

    const entrypointUrl = new URL(entrypoint, window.location.href);
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

    await import(new URL(script.getAttribute('src')!, entrypointUrl).href);
  } catch (error) {
    agentRoot.dataset.mountError = 'true';
    console.error(error);
  }
}

function documentHasStylesheet(href:string, entrypointUrl:URL):boolean {
  const absoluteHref = new URL(href, entrypointUrl).href;

  return Array.from(window.document.querySelectorAll<HTMLLinkElement>('link[rel="stylesheet"]'))
    .some((link) => link.href === absoluteHref);
}
