import type { TreeNode } from "./types/TreeNode";
import { ignoredPatterns } from "./config";
import { readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

export function buildTree(dir: string, base: string = dir): TreeNode[] {
  const result: TreeNode[] = [];

  for (const entry of readdirSync(dir)) {
    const fullPath = join(dir, entry);

    if (ignoredPatterns.some((pattern) => fullPath.includes(pattern))) {
      continue;
    }

    const stats = statSync(fullPath);
    const relPath = relative(base, fullPath);

    if (stats.isDirectory()) {
      result.push({
        type: "dir",
        name: entry,
        relPath,
        children: buildTree(fullPath, base),
        selected: false,
        expanded: true,
      });
    } else {
      result.push({
        type: "file",
        name: entry,
        relPath,
        selected: false,
        expanded: false,
      });
    }
  }

  return result;
}
