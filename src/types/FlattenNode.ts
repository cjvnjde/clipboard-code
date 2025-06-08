import type { TreeNode } from "./TreeNode";

export type FlattenedNode = {
  node: TreeNode;
  depth: number;
  isLast: boolean;
  ancestorsLast: boolean[];
};
