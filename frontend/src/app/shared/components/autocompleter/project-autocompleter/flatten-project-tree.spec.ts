import { IProjectAutocompleteItemTree } from './project-autocomplete-item';
import { flattenProjectTree } from './flatten-project-tree';

const treeNode = (id:string, name = `Project ${id}`):IProjectAutocompleteItemTree => ({
  id,
  href: `/api/v3/projects/${id}`,
  name,
  disabled: false,
  children: [],
});

describe('flattenProjectTree', () => {
  it('flattens in depth-first order while preserving depth', () => {
    const root = treeNode('1');
    const childA = treeNode('2');
    const childB = treeNode('3');
    const grandChild = treeNode('4');

    childA.children = [grandChild];
    root.children = [childA, childB];

    const flat = flattenProjectTree([root]);
    expect(flat.map((item) => item.id)).toEqual(['1', '2', '4', '3']);
    expect(flat.map((item) => item.numberOfAncestors)).toEqual([0, 1, 2, 1]);
  });

  it('handles very deep trees without recursion overflow', () => {
    const root = treeNode('0');
    let current = root;

    Array.from({ length: 20000 }, (_, index) => (index + 1).toString()).forEach((id) => {
      const child = treeNode(id);
      current.children = [child];
      current = child;
    });

    expect(() => flattenProjectTree([root])).not.toThrow();
  });

  it('breaks cyclic references instead of recursing forever', () => {
    const root = treeNode('1');
    const child = treeNode('2');

    root.children = [child];
    child.children = [root];

    const flat = flattenProjectTree([root]);
    expect(flat.map((item) => item.id)).toEqual(['1', '2']);
  });
});
