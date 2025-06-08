import type { FlattenedNode } from "./types/FlattenNode";
import type { TreeNode } from "./types/TreeNode";

export function flattenTree(
  nodes: TreeNode[],
  depth = 0,
  ancestorsLast: boolean[] = [],
): FlattenedNode[] {
  let flat: FlattenedNode[] = [];

  nodes.forEach((node, idx) => {
    const isLast = idx === nodes.length - 1;
    flat.push({ node, depth, isLast, ancestorsLast });
    if (node.children && node.children.length) {
      flat = flat.concat(
        flattenTree(node.children, depth + 1, [...ancestorsLast, isLast]),
      );
    }
  });

  return flat;
}
