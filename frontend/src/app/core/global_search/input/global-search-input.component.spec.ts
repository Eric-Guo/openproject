import { ElementRef } from '@angular/core';
import { BehaviorSubject, of } from 'rxjs';

import { GlobalSearchInputComponent } from './global-search-input.component';

describe('GlobalSearchInputComponent', () => {
  let component:GlobalSearchInputComponent;
  let header:HTMLDivElement;
  let searchInput:HTMLInputElement;
  let typeahead:BehaviorSubject<string>;
  let typeaheadNextSpy:jasmine.Spy;
  let searchSignalSetSpy:jasmine.Spy;
  let originalPath:string;

  beforeEach(() => {
    originalPath = window.location.pathname + window.location.search + window.location.hash;
    header = document.createElement('div');
    header.className = 'op-app-header';
    document.body.appendChild(header);

    searchInput = document.createElement('input');
    typeahead = new BehaviorSubject<string>('');
    typeaheadNextSpy = spyOn(typeahead, 'next').and.callThrough();
    const searchTermStateKey = '_searchTerm';

    const ngSelectInstance = {
      searchTerm: '',
      searchInput: jasmine.createSpy('searchInput').and.returnValue({ nativeElement: searchInput }),
      [searchTermStateKey]: {
        set: jasmine.createSpy('set').and.callFake((searchTerm:string) => {
          ngSelectInstance.searchTerm = searchTerm;
        }),
      },
    };

    searchSignalSetSpy = ngSelectInstance[searchTermStateKey].set;

    component = new GlobalSearchInputComponent(
      new ElementRef(document.createElement('div')),
      { t:(key:string) => key } as never,
      {} as never,
      {} as never,
      {} as never,
      { submitSearch: jasmine.createSpy('submitSearch') } as never,
      { path: null } as never,
      { isTablet: false, isMobile: false } as never,
      { detectChanges: jasmine.createSpy('detectChanges') } as never,
      {} as never,
      {} as never,
      { recentItems$: of([]) } as never,
    );

    component.ngSelectComponent = {
      ngSelectInstance,
      typeahead,
    } as never;
  });

  afterEach(() => {
    history.replaceState({}, '', originalPath);
    header.remove();
  });

  it('propagates a preloaded query into ng-select state on init', () => {
    history.replaceState({}, '', '/?q=OpenProject');

    component.ngAfterViewInit();

    expect(component.searchTerm).toBe('OpenProject');
    expect(component.currentValue).toBe('OpenProject');
    expect(searchInput.value).toBe('OpenProject');
    expect(searchSignalSetSpy).toHaveBeenCalledOnceWith('OpenProject');
    expect(typeaheadNextSpy).toHaveBeenCalledOnceWith('OpenProject');
  });

  it('does not retrigger ng-select state updates for the same term', () => {
    component.searchTerm = 'OpenProject';
    searchSignalSetSpy.calls.reset();
    typeaheadNextSpy.calls.reset();

    component.searchTerm = 'OpenProject';

    expect(searchSignalSetSpy).not.toHaveBeenCalled();
    expect(typeaheadNextSpy).not.toHaveBeenCalled();
  });
});
