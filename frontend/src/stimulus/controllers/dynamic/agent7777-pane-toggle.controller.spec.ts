//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import '@testing-library/jest-dom/vitest';
import { setupStimulusTest, type StimulusTestContext } from '../../test-helpers';
import Agent7777PaneToggleController from './agent7777-pane-toggle.controller';

describe('Agent7777 pane toggle controller', () => {
  let ctx:StimulusTestContext;
  let storedValues:Map<string, string>;
  let originalOpenProject:typeof window.OpenProject;

  beforeEach(async () => {
    storedValues = new Map();
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      guardedLocalStorage: (key:string, value?:string) => {
        if (value !== undefined) storedValues.set(key, value);
        return storedValues.get(key) ?? null;
      },
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'agent7777-pane-toggle': Agent7777PaneToggleController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
  });

  async function renderController(mainClass = 'with-agent7777') {
    await ctx.mount(`
      <div data-controller="agent7777-pane-toggle">
        <button
          hidden
          aria-expanded="true"
          data-action="click->agent7777-pane-toggle#toggle"
          data-agent7777-pane-toggle-target="button"
          data-expanded-label="Collapse 7777 agent pane"
          data-collapsed-label="Expand 7777 agent pane">
        </button>
        <main class="${mainClass}" data-agent7777-pane-toggle-target="main"></main>
        <aside data-agent7777-pane-toggle-target="pane"></aside>
      </div>
    `);
    await ctx.nextFrame();

    return {
      button: ctx.container.querySelector('button')!,
      main: ctx.container.querySelector('main')!,
      pane: ctx.container.querySelector('aside')!,
    };
  }

  it('collapses and expands the pane while persisting the state', async () => {
    const { button, main, pane } = await renderController();

    expect(button.hidden).toBe(false);
    button.click();
    await ctx.nextFrame();

    expect(main).toHaveClass('agent7777-pane-collapsed');
    expect(button).toHaveAttribute('aria-expanded', 'false');
    expect(button).toHaveAttribute('aria-label', 'Expand 7777 agent pane');
    expect(pane).toHaveAttribute('aria-hidden', 'true');
    expect(storedValues.get('openProject-agent7777PaneCollapsed')).toBe('true');

    button.click();
    await ctx.nextFrame();

    expect(main).not.toHaveClass('agent7777-pane-collapsed');
    expect(button).toHaveAttribute('aria-expanded', 'true');
    expect(pane).not.toHaveAttribute('aria-hidden');
    expect(storedValues.get('openProject-agent7777PaneCollapsed')).toBe('false');
  });

  it('restores a persisted collapsed state', async () => {
    storedValues.set('openProject-agent7777PaneCollapsed', 'true');

    const { button, main } = await renderController();

    expect(main).toHaveClass('agent7777-pane-collapsed');
    expect(button).toHaveAttribute('aria-expanded', 'false');
  });

  it('updates Primer tooltip labels and exposes the button name directly', async () => {
    await ctx.mount(`
      <div data-controller="agent7777-pane-toggle">
        <button
          aria-labelledby="agent7777-tooltip"
          data-agent7777-pane-toggle-target="button"
          data-expanded-label="Collapse 7777 agent pane"
          data-collapsed-label="Expand 7777 agent pane">
        </button>
        <tool-tip id="agent7777-tooltip">Old label</tool-tip>
        <main class="with-agent7777" data-agent7777-pane-toggle-target="main"></main>
        <aside data-agent7777-pane-toggle-target="pane"></aside>
      </div>
    `);
    await ctx.nextFrame();

    const button = ctx.container.querySelector('button')!;

    expect(button).not.toHaveAttribute('aria-labelledby');
    expect(button).toHaveAttribute('aria-label', 'Collapse 7777 agent pane');
    expect(ctx.container.querySelector('tool-tip')).toHaveTextContent('Collapse 7777 agent pane');
  });

  it('only shows the toggle when the agent pane is available', async () => {
    const { button, main } = await renderController('');

    expect(button.hidden).toBe(true);

    main.classList.add('with-agent7777');
    await ctx.nextFrame();

    expect(button.hidden).toBe(false);
  });
});
