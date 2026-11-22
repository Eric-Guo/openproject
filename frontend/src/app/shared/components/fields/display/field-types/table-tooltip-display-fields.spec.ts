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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { ProviderToken } from '@angular/core';
import { fireEvent, within, waitFor } from '@testing-library/dom';
import { DisplayFieldRenderer } from '../display-field-renderer';
import { DisplayFieldService } from '../display-field.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { LinkedWorkPackageDisplayField } from './linked-work-package-display-field.module';
import { WorkDisplayField } from './work-display-field.module';
import { CompoundProgressDisplayField } from './compound-progress-display-field.module';
import { WorkPackageSpentTimeDisplayField } from './wp-spent-time-display-field.module';
import { HierarchyQueryLinkHelperService } from './hierarchy-query-link-helper.service';
import { ExcludedIconHelperService } from './excluded-icon-helper.service';

const translations:Record<string, string> = {
  'js.label_value_derived_from_children': 'Value derived from children',
  'js.work_packages.message_view_spent_time': 'View spent time',
  'js.button_log_time': 'Log time',
  'js.work_packages.message_successful_show_in_fullscreen': 'Open full view',
};

describe('table field tooltips', () => {
  let container:HTMLElement;
  let context:DisplayFieldContext;

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'));

    const services = new Map<unknown, unknown>([
      [I18nService, { t: (key:string) => translations[key] ?? key }],
      [TimezoneService, { formattedChronicDuration: () => '4 h' }],
      [KeepTabService, { currentShowTab: 'activity' }],
      [CurrentProjectService, { identifier: 'demo' }],
      [UrlParamsService, { basePathWithoutDetails: () => '/work_packages' }],
      [
        PathHelperService,
        {
          genericWorkPackagePath: (_project:string, id:string) => `/work_packages/${id}`,
        },
      ],
      [
        HierarchyQueryLinkHelperService,
        { addHref: (link:HTMLAnchorElement) => { link.href = '/children'; } },
      ],
      [ExcludedIconHelperService, { addIconIfExcludedFromTotals: vi.fn() }],
    ]);

    context = { injector: { get: (token:unknown) => services.get(token) ?? {} }, options: {} } as unknown as DisplayFieldContext;
  });

  afterEach(() => { container.remove(); });

  it.each([WorkDisplayField, CompoundProgressDisplayField])('describes derived values with %s', (FieldClass) => {
    const field = new FieldClass('work', context);
    field.apply({ work: 40, derivedWork: 60, children: [] } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '40');

    const link = within(container).getByRole('link');
    expect(link).toHaveAccessibleName(FieldClass === WorkDisplayField ? 'Σ 4 h' : 'Σ 60%');
    expect(link).toHaveAccessibleDescription('Value derived from children');
    expect(link).toHaveAttribute('href', '/children');
    expect(link).toHaveClass('-derived-value', '__ui-state-link');
    expect(link).toHaveAttribute('title', '');
    expect(field.title).toBeNull();
    expect(container.title).toBe('');
    expect(container.querySelector('tool-tip')).toHaveTextContent(/^Value derived from children$/);
  });

  it('renders historic derived work without a link', () => {
    const field = new WorkDisplayField('work', { ...context, options: { historic: true } });
    field.apply({ work: 40, derivedWork: 60 } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '40');

    const derived = container.querySelector('.-derived-value');
    expect(within(container).queryByRole('link')).toBeNull();
    expect(derived).toHaveTextContent('Σ 4 h');
    expect(derived).not.toHaveClass('__ui-state-link');
    expect(container.querySelector('tool-tip')).toHaveTextContent(/^Value derived from children$/);
  });

  it('does not restore a compound container title through DisplayFieldRenderer', () => {
    const field = new CompoundProgressDisplayField('work', context);
    const schema = { ofProperty: () => ({}), isAttributeEditable: () => false };
    const services = new Map<unknown, unknown>([
      [DisplayFieldService, { getField: () => field }],
      [SchemaCacheService, { of: () => schema }],
      [HalResourceEditingService, { typedState: () => ({ hasValue: () => false }) }],
    ]);

    const injector = { get: (token:ProviderToken<unknown>) => services.get(token) ?? context.injector.get(token) };
    const renderer = new DisplayFieldRenderer(injector, 'table');
    const [, span] = renderer.renderFieldValue({ work: 40, derivedWork: 60, children: [] } as unknown as HalResource, 'work', null);
    container.append(span);

    expect(span).not.toHaveAttribute('title');
    expect(within(span).getByRole('link')).toHaveAttribute('title', '');
  });


  it('disconnects spent-time tooltip listeners when its field rerenders', async () => {
    const field = new WorkPackageSpentTimeDisplayField('spentTime', context);
    field.apply({ spentTime: 'PT4H' } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '4 h');

    const oldLink = container.querySelector('a')!;
    const oldTooltip = container.querySelector<InstanceType<typeof window.ToolTipElement>>('tool-tip')!;
    fireEvent.mouseEnter(oldLink);
    await waitFor(() => expect(oldTooltip.matches(':popover-open')).toBe(true));

    const oldHandler = vi.spyOn(oldTooltip, 'handleEvent');
    field.render(container, '8 h');

    expect(oldTooltip).not.toBeInTheDocument();
    expect(container.querySelectorAll('tool-tip')).toHaveLength(1);
    fireEvent.mouseEnter(oldLink);

    expect(oldHandler).not.toHaveBeenCalled();

    const newLink = container.querySelector('a')!;
    const newTooltip = container.querySelector('tool-tip')!;
    fireEvent.mouseEnter(newLink);
    await waitFor(() => expect(newTooltip.matches(':popover-open')).toBe(true));
  });

  it('retains linked work-package routing and its visible ID', () => {
    const field = new LinkedWorkPackageDisplayField('parent', context);
    field.apply({ parent: { id: '42', displayId: 'DEMO-7', formattedId: 'DEMO-7', name: 'Parent subject', $loaded: true } } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '');

    const link = within(container).getByRole('link', { name: 'DEMO-7' });
    expect(link).toHaveAccessibleDescription('Open full view');
    expect(link).toHaveAttribute('title', '');
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('href', expect.stringContaining('/work_packages/DEMO-7'));
    expect(container).toHaveTextContent('Parent subject');
  });


  it('labels the spent-time report and external time entry links', () => {
    const field = new WorkPackageSpentTimeDisplayField('spentTime', context);
    const href = '/projects/demo/time_entries?values[WorkPackageId]=42';
    field.apply({ spentTime: 'PT4H', showSpentTime: { href }, logTime: {} } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '4 h');

    const report = within(container).getByRole('link', { name: '4 h' });
    expect(report).toHaveAccessibleDescription('View spent time');
    expect(report).toHaveAttribute('title', '');
    expect(report).toHaveAttribute('href', href);

    const log = within(container).getByRole<HTMLAnchorElement>('link', { name: 'Log time' });
    expect(log).toHaveAccessibleDescription('');
    expect(log).toHaveClass('icon', 'icon-time');
    expect(log.target).toBe('th_keyin');
    const destination = new URL(log.href);
    expect(destination.origin).toBe('https://ith-workspace.thape.com.cn');
    expect(destination.searchParams.get('redirect_uri')).toBe('https://ith-workspace.thape.com.cn/ith-worktime/day');
  });

  it('shows the spent time as text when the resource has no report or logging link', () => {
    const field = new WorkPackageSpentTimeDisplayField('spentTime', context);
    field.apply({ spentTime: 'PT4H' } as unknown as HalResource, {} as IFieldSchema);
    field.render(container, '4 h');

    expect(container).toHaveTextContent('4 h');
    expect(within(container).queryByRole('link')).toBeNull();
  });
});
