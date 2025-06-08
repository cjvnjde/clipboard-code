import { Box, useApp, useFocusManager } from "ink";
import { TreeView } from "./TreeView";
import type { TreeNode } from "../types/TreeNode";
import { useCallback, useEffect } from "react";
import { buildClipboardContent } from "../buildClipboardContent";
import { copyToClipboard } from "../utils/copyToClipboard";

function getSelected(node: TreeNode): string[] {
  if (node.selected && node.type === "file") return [node.relPath];
  let res: string[] = [];
  if (node.type === "dir" && node.children) {
    for (const c of node.children) res = res.concat(getSelected(c));
    if (node.selected) res.push(node.relPath + "/");
  }
  return res;
}

export const App = ({
  tree,
  basePath,
}: {
  tree: TreeNode[];
  basePath: string;
}) => {
  const { enableFocus } = useFocusManager();
  const { exit } = useApp();

  useEffect(() => {
    enableFocus();
  }, []);

  const handleSubmit = useCallback((tree: TreeNode[]) => {
    let all: string[] = [];
    for (const t of tree) all = all.concat(getSelected(t));
    const content = buildClipboardContent(all, basePath);
    copyToClipboard(content);
    exit();
  }, []);

  return (
    <Box flexDirection="column">
      <TreeView tree={tree} onSubmit={handleSubmit} />
    </Box>
  );
};
