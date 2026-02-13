import { IProjectAutocompleteItem, IProjectAutocompleteItemTree } from './project-autocomplete-item';

interface IFlattenStackEntry {
  node:IProjectAutocompleteItemTree;
  depth:number;
  path:Set<string>;
}

export const flattenProjectTree = (
  projectTreeItems:IProjectAutocompleteItemTree[],
  depth = 0,
):IProjectAutocompleteItem[] => {
  const fullList:IProjectAutocompleteItem[] = [];
  const stack:IFlattenStackEntry[] = [];

  projectTreeItems.slice().reverse().forEach((projectTreeItem) => {
    stack.push({
      node: projectTreeItem,
      depth,
      path: new Set<string>(),
    });
  });

  while (stack.length > 0) {
    const { node, depth: level, path } = stack.pop()!;
    if (path.has(node.href)) {
      continue;
    }

    const nextPath = new Set(path);
    nextPath.add(node.href);

    fullList.push({
      ...node,
      numberOfAncestors: level,
      // The actual list of ancestors does not matter anymore from this point forward,
      // but to keep typing straightforward for consumers of this component that use mapResultsFn,
      // it is marked as required in the interface.
      ancestors: [],
    });

    node.children.slice().reverse().forEach((child) => {
      stack.push({
        node: child,
        depth: level + 1,
        path: nextPath,
      });
    });
  }

  return fullList;
};
