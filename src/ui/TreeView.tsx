import { Box, Text, useFocus, useFocusManager, useInput } from "ink";
import { flattenTree } from "../flattenTree";
import type { TreeNode } from "../types/TreeNode";
import type { FlattenedNode } from "../types/FlattenNode";
import { useCallback, useMemo, useState } from "react";
import { produce } from "immer";

function setSelectionRecursive(node: TreeNode, selected: boolean) {
  node.selected = selected;

  if (node.children) {
    node.children.forEach((child) => setSelectionRecursive(child, selected));
  }
}

function findNodeAndParents(
  nodes: TreeNode[],
  relPath: string,
  parents: TreeNode[] = [],
): { node: TreeNode | null; parents: TreeNode[] } {
  for (const node of nodes) {
    if (node.relPath === relPath) {
      return { node, parents };
    }

    if (node.children) {
      const found = findNodeAndParents(node.children, relPath, [
        ...parents,
        node,
      ]);

      if (found.node) {
        return found;
      }
    }
  }
  return { node: null, parents: [] };
}

function getTreePrefix(
  depth: number,
  isLast: boolean,
  ancestorsLast: boolean[],
) {
  let prefix = "";

  if (depth === 0) {
    return "";
  }

  for (let i = 0; i < depth; i++) {
    prefix += ancestorsLast[i] ? "" : "│  ";
  }

  prefix += isLast ? "└─ " : "├─ ";

  return prefix;
}

type TreeRowProps = {
  node: FlattenedNode;
  onSelect: (node: FlattenedNode) => void;
};

const TreeRow = ({ node: flattenedNode, onSelect }: TreeRowProps) => {
  const { depth, isLast, ancestorsLast, node } = flattenedNode;
  const { isFocused } = useFocus({ autoFocus: true });

  useInput(
    (input) => {
      if (input === " ") {
        onSelect(flattenedNode);
      }
    },
    { isActive: isFocused },
  );

  return (
    <Box>
      <Text color={isFocused ? "green" : "white"}>
        {node.selected ? "[x]" : "[ ]"}{" "}
        {getTreePrefix(depth, isLast, ancestorsLast)}
        {node.type === "dir" ? node.name + "/" : node.name}
      </Text>
    </Box>
  );
};

type TreeViewProps = {
  tree: TreeNode[];
  onSubmit?: (tree: TreeNode[]) => void;
};
export const TreeView = ({ tree: initialTree, onSubmit }: TreeViewProps) => {
  const [tree, setTree] = useState(initialTree);
  const flatTree = useMemo(() => flattenTree(tree), [tree]);
  const { focusNext, focusPrevious } = useFocusManager();

  useInput((input, key) => {
    if (key.downArrow || input === "j") {
      focusNext();
    }

    if (key.upArrow || input === "k") {
      focusPrevious();
    }

    if (key.return) {
      onSubmit?.(tree);
    }
  });

  const handleToggle = useCallback((flattenedNode: FlattenedNode) => {
    setTree((prevTree) => {
      const nextTree = produce(prevTree, (draft) => {
        const { node, parents } = findNodeAndParents(
          draft,
          flattenedNode.node.relPath,
        );

        if (!node) return;
        if (node.type === "dir") {
          setSelectionRecursive(node, !node.selected);
        } else {
          node.selected = !node.selected;
        }

        for (let i = parents.length - 1; i >= 0; i--) {
          const parent = parents[i]!;

          if (parent.children) {
            parent.selected = parent.children.every((c) => c.selected);
          }
        }
      });

      return nextTree;
    });
  }, []);

  return (
    <Box flexDirection="column">
      {flatTree.map((flattenedNode) => (
        <TreeRow
          node={flattenedNode}
          key={flattenedNode.node.relPath}
          onSelect={handleToggle}
        />
      ))}
      <Box marginTop={1}>
        <Text dimColor>
          Use arrows to move, [space] to toggle, [enter] to finish.
        </Text>
      </Box>
    </Box>
  );
};
