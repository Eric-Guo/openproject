import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import {
  IProjectAutocompleteItem,
  IProjectAutocompleteItemTree,
} from './project-autocomplete-item';

const UNDISCLOSED_ANCESTOR = 'urn:openproject-org:api:v3:undisclosed';

const insertProjectWithAncestors = (
  tree:IProjectAutocompleteItemTree[],
  project:IProjectAutocompleteItem,
  ancestors:IHalResourceLink[],
):IProjectAutocompleteItemTree[] => {
  const visibleAncestors = ancestors.filter((ancestor) => ancestor.href !== UNDISCLOSED_ANCESTOR);
  const visitedHrefs = new Set<string>([project.href]);
  let currentLevel = tree;

  visibleAncestors.some((ancestor) => {
    const ancestorHref = ancestor.href;

    // Protect against malformed project hierarchies that contain cycles or repeated ancestors.
    if (visitedHrefs.has(ancestorHref)) {
      return true;
    }
    visitedHrefs.add(ancestorHref);

    let ancestorInTree = currentLevel.find((leaf) => leaf.href === ancestorHref);
    if (!ancestorInTree) {
      ancestorInTree = {
        id: idFromLink(ancestorHref),
        name: ancestor.title,
        href: ancestorHref,
        disabled: true,
        children: [],
      };
      currentLevel.push(ancestorInTree);
    }

    currentLevel = ancestorInTree.children;
    return false;
  });

  currentLevel.push({
    ...project,
    children: [],
  });

  return tree;
};

export const buildTree = (
  projects:IProjectAutocompleteItem[],
):IProjectAutocompleteItemTree[] => projects.reduce(
  // The ancestors are listed from direct parent up to root. We'll build a tree structure for these ancestors here.
  // Some might already exist from other children that added them to the tree, or because they were part of the result
  // list themselves. However, if they're not available yet we'll need to generate them.
  (tree, project) => insertProjectWithAncestors(tree, project, project.ancestors),
  [],
);
