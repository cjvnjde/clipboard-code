export type TreeNode = {
  type: "dir" | "file";
  name: string;
  relPath: string;
  children?: TreeNode[];
  selected: boolean;
  expanded: boolean;
};
