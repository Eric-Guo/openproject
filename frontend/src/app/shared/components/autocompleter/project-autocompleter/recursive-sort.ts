import { IProjectAutocompleteItemTree } from './project-autocomplete-item';

interface ISortStackEntry {
  node:IProjectAutocompleteItemTree;
  target:IProjectAutocompleteItemTree[];
  path:Set<string>;
}

const byName = (a:{ name:string }, b:{ name:string }) => a.name.localeCompare(b.name);

// Sort all levels by name using iterative DFS to avoid call stack overflow on deep trees.
export const recursiveSort = (projects:IProjectAutocompleteItemTree[]):IProjectAutocompleteItemTree[] => {
  const sortedTree:IProjectAutocompleteItemTree[] = [];
  const stack:ISortStackEntry[] = [];
  const sortedRoots = [...projects].sort(byName);

  sortedRoots.slice().reverse().forEach((project) => {
    stack.push({
      node: project,
      target: sortedTree,
      path: new Set<string>(),
    });
  });

  while (stack.length > 0) {
    const { node, target, path } = stack.pop()!;
    if (path.has(node.href)) {
      continue;
    }

    const nextPath = new Set(path);
    nextPath.add(node.href);

    const sortedNode:IProjectAutocompleteItemTree = {
      ...node,
      children: [],
    };
    target.push(sortedNode);

    const sortedChildren = [...node.children].sort(byName);
    sortedChildren.slice().reverse().forEach((child) => {
      stack.push({
        node: child,
        target: sortedNode.children,
        path: nextPath,
      });
    });
  }

  return sortedTree;
};
