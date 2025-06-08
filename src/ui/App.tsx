import { Box, useInput, useApp, useFocusManager } from "ink";
import { TreeView } from "./TreeView";
import type { TreeNode } from "../types/TreeNode";
import { useCallback, useEffect, useState } from "react";
import { buildClipboardContent } from "../buildClipboardContent";
import { copyToClipboard } from "../utils/copyToClipboard";
import { SearchInput } from "./SearchInput";
import { useAtom } from "jotai";
import { searchFilterAtom } from "../state/filterState";
import { modeStateAtom } from "../state/modeState";

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

  const [mode, setMode] = useAtom(modeStateAtom);
  const [searchQuery, setSearchQuery] = useAtom(searchFilterAtom);

  useInput((input, key) => {
    if (mode !== "search" && input === "f") {
      setMode("search");
      return;
    }
    if (mode !== "normal" && key.escape) {
      setMode("normal");
      setSearchQuery("");
      return;
    }
  });

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
      {mode === "search" && (
        <SearchInput query={searchQuery} setQuery={setSearchQuery} />
      )}
      <TreeView tree={tree} onSubmit={handleSubmit} />
    </Box>
  );
};
