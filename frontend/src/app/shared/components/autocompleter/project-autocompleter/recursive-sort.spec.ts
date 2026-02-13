import { IProjectAutocompleteItemTree } from './project-autocomplete-item';
import { recursiveSort } from './recursive-sort';

const treeNode = (id:string, name = `Project ${id}`):IProjectAutocompleteItemTree => ({
  id,
  href: `/api/v3/projects/${id}`,
  name,
  disabled: false,
  children: [],
});

describe('recursiveSort', () => {
  it('sorts all levels by project name', () => {
    const a = treeNode('1', 'A');
    const b = treeNode('2', 'B');
    const c = treeNode('3', 'C');
    const d = treeNode('4', 'D');

    a.children = [d, c];
    const sorted = recursiveSort([b, a]);

    expect(sorted.map((item) => item.name)).toEqual(['A', 'B']);
    expect(sorted[0].children.map((item) => item.name)).toEqual(['C', 'D']);
  });

  it('handles very deep trees without recursion overflow', () => {
    const root = treeNode('0');
    let current = root;

    Array.from({ length: 20000 }, (_, index) => (index + 1).toString()).forEach((id) => {
      const child = treeNode(id);
      current.children = [child];
      current = child;
    });

    expect(() => recursiveSort([root])).not.toThrow();
  });

  it('breaks cyclic references instead of recursing forever', () => {
    const root = treeNode('1');
    const child = treeNode('2');

    root.children = [child];
    child.children = [root];

    const sorted = recursiveSort([root]);
    expect(sorted.length).toBe(1);
    expect(sorted[0].children.length).toBe(1);
    expect(sorted[0].children[0].children.length).toBe(0);
  });
});
