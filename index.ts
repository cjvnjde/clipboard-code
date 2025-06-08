#!/usr/bin/env bun

import { readdirSync, statSync, readFileSync } from "node:fs";
import { join, relative, extname, basename } from "node:path";
import readline from "node:readline";
import { spawn } from "node:child_process";

type TreeNode = {
  type: "dir" | "file";
  name: string;
  relPath: string;
  children?: TreeNode[];
  selected: boolean;
  expanded: boolean;
};

const ignoredPatterns = [
  "node_modules",
  ".git",
  "dist",
  "build",
  "out",
  "coverage",
];

function getFileType(filename: string) {
  const ext = extname(filename).toLowerCase().replace(".", "");
  const base = basename(filename).toLowerCase();

  const extToLang: Record<string, string> = {
    js: "javascript",
    mjs: "javascript",
    cjs: "javascript",
    ts: "typescript",
    tsx: "tsx",
    jsx: "jsx",
    json: "json",
    css: "css",
    scss: "scss",
    sass: "sass",
    less: "less",
    html: "html",
    htm: "html",
    md: "markdown",
    markdown: "markdown",
    yml: "yaml",
    yaml: "yaml",
    sh: "bash",
    bash: "bash",
    zsh: "zsh",
    py: "python",
    go: "go",
    rs: "rust",
    java: "java",
    c: "c",
    h: "c",
    cpp: "cpp",
    cc: "cpp",
    cxx: "cpp",
    hpp: "cpp",
    cs: "csharp",
    php: "php",
    rb: "ruby",
    pl: "perl",
    swift: "swift",
    kt: "kotlin",
    dart: "dart",
    sql: "sql",
    ini: "ini",
    env: "env",
    toml: "toml",
    xml: "xml",
    txt: "text",
    dockerfile: "docker",
    makefile: "makefile",
    vue: "vue",
    svelte: "svelte",
    lock: "text",
    log: "text",
  };

  if (ext in extToLang) return extToLang[ext];

  if (base === ".bashrc" || base === ".bash_profile" || base === ".profile")
    return "bash";
  if (base === ".zshrc" || base === ".zshenv") return "zsh";
  if (base === ".env" || base.endsWith(".env")) return "env";
  if (base === "dockerfile") return "docker";
  if (base === "makefile") return "makefile";
  if (base === "license") return "text";
  if (base === "readme" || base.startsWith("readme.")) return "markdown";
  if (base === "gitignore") return "gitignore";
  if (base === "npmrc") return "ini";
  if (base === "prettierrc" || base.endsWith("prettierrc")) return "json";
  if (base === "eslintrc" || base.endsWith("eslintrc")) return "json";
  if (
    base === "yarn.lock" ||
    base === "pnpm-lock.yaml" ||
    base === "package-lock.json"
  )
    return "text";

  return "text";
}

function buildTree(dir: string, base: string): TreeNode[] {
  const result: TreeNode[] = [];

  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (ignoredPatterns.some((pattern) => full.includes(pattern))) continue;
    const stats = statSync(full);
    const relPath = relative(base, full);
    if (stats.isDirectory()) {
      result.push({
        type: "dir",
        name: entry,
        relPath,
        children: buildTree(full, base),
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

function flattenTree(
  tree: TreeNode[],
  depth = 0,
  out: { node: TreeNode; depth: number }[] = [],
) {
  for (const node of tree) {
    out.push({ node, depth });
    if (node.type === "dir" && node.expanded && node.children) {
      flattenTree(node.children, depth + 1, out);
    }
  }
  return out;
}

function setSelected(node: TreeNode, selected: boolean) {
  node.selected = selected;
  if (node.type === "dir" && node.children) {
    for (const child of node.children) setSelected(child, selected);
  }
}

function areAllSelected(tree: TreeNode[]): boolean {
  for (const node of tree) {
    if (!node.selected) return false;
    if (node.type === "dir" && node.children && !areAllSelected(node.children))
      return false;
  }
  return true;
}

function setAllSelected(tree: TreeNode[], selected: boolean) {
  for (const node of tree) {
    setSelected(node, selected);
  }
}

function render(
  flat: { node: TreeNode; depth: number }[],
  cursor: number,
  tree: TreeNode[],
) {
  process.stdout.write("\x1Bc"); // clear screen

  const allSelected = areAllSelected(tree);
  const pointer = cursor === 0 ? ">" : " ";
  const checkbox = allSelected ? "[x]" : "[ ]";
  console.log(`${pointer} ${checkbox} Select All`);

  for (let i = 0; i < flat.length; ++i) {
    const item = flat[i];
    if (!item) continue;
    const { node, depth } = item;
    const pointer = cursor === i + 1 ? ">" : " ";
    const checkbox = node.selected ? "[x]" : "[ ]";
    const indent = "  ".repeat(depth);
    const name = node.type === "dir" ? node.name + "/" : node.name;
    console.log(`${pointer} ${indent}${checkbox} ${name}`);
  }
  console.log("\nUse arrows to move, [space] to toggle, [enter] to finish.");
}

function getSelected(node: TreeNode): string[] {
  if (node.selected && node.type === "file") return [node.relPath];
  let res: string[] = [];
  if (node.type === "dir" && node.children) {
    for (const c of node.children) res = res.concat(getSelected(c));
    // Optionally, include folder itself if selected
    if (node.selected) res.push(node.relPath + "/");
  }
  return res;
}

function buildClipboardContent(selectedFiles: string[], base: string) {
  let out = "";
  for (const file of selectedFiles) {
    if (file.endsWith("/")) continue; // skip directories
    const full = join(base, file);
    let fileType = getFileType(file);
    let content;
    try {
      content = readFileSync(full, "utf8");
    } catch (e) {
      content = "[ERROR READING FILE]";
    }
    out += `${file}\n\`\`\`${fileType}\n${content}\n\`\`\`\n\n`;
  }
  return out.trim();
}

async function main() {
  const base = process.cwd();
  const tree = buildTree(base, base);

  let flat = flattenTree(tree);
  let cursor = 0;

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  readline.emitKeypressEvents(process.stdin, rl);

  process.stdin.setRawMode(true);

  function rerender() {
    flat = flattenTree(tree);
    render(flat, cursor, tree);
  }

  rerender();

  process.stdin.on("keypress", (_str, key) => {
    if (key.name === "down") {
      if (cursor < flat.length) cursor++; // +1 for "select all"
      rerender();
    } else if (key.name === "up") {
      if (cursor > 0) cursor--;
      rerender();
    } else if (key.name === "space") {
      if (cursor === 0) {
        const select = !areAllSelected(tree);
        setAllSelected(tree, select);
      } else {
        const current = flat[cursor - 1]?.node;
        if (current) {
          setSelected(current, !current.selected);
        }
      }
      rerender();
    } else if (key.name === "return") {
      process.stdin.setRawMode(false);
      rl.close();
      let all: string[] = [];
      for (const t of tree) all = all.concat(getSelected(t));
      const content = buildClipboardContent(all, base);
      spawn("wl-copy", [content], { stdio: "ignore" }).on("error", () => {});
      console.log("\nCopied selected files to clipboard!\n");
      console.log("\nSelected:\n" + all.join("\n"));
      process.exit(0);
    } else if (key.ctrl && key.name === "c") {
      process.exit(0);
    }
  });
}

main();
