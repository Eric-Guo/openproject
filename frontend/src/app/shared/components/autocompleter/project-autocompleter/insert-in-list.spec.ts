import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import {
  IProjectAutocompleteItem,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';
import { buildTree } from 'core-app/shared/components/autocompleter/project-autocompleter/insert-in-list';

const ancestor = (id:string):IHalResourceLink => ({
  href: `/api/v3/projects/${id}`,
  title: `Project ${id}`,
});

const project = (id:string, ancestors:IHalResourceLink[]):IProjectAutocompleteItem => ({
  id,
  href: `/api/v3/projects/${id}`,
  name: `Project ${id}`,
  disabled: false,
  ancestors,
});

describe('buildTree', () => {
  it('ignores undisclosed ancestors', () => {
    const tree = buildTree([
      project('3', [
        { href: 'urn:openproject-org:api:v3:undisclosed', title: 'Undisclosed' },
        ancestor('1'),
      ]),
    ]);

    expect(tree.length).toBe(1);
    expect(tree[0].href).toBe('/api/v3/projects/1');
    expect(tree[0].children.length).toBe(1);
    expect(tree[0].children[0].href).toBe('/api/v3/projects/3');
  });

  it('stops at repeated ancestors and still inserts the project', () => {
    const tree = buildTree([
      project('9', [ancestor('1'), ancestor('2'), ancestor('1')]),
    ]);

    expect(tree.length).toBe(1);
    expect(tree[0].href).toBe('/api/v3/projects/1');
    expect(tree[0].children.length).toBe(1);
    expect(tree[0].children[0].href).toBe('/api/v3/projects/2');
    expect(tree[0].children[0].children.length).toBe(1);
    expect(tree[0].children[0].children[0].href).toBe('/api/v3/projects/9');
  });

  it('handles very deep ancestor lists without recursion overflow', () => {
    const deepAncestors = Array.from({ length: 20000 }, (_, index) => ancestor((index + 1).toString()));

    expect(() => buildTree([project('99999', deepAncestors)])).not.toThrow();
  });
});
