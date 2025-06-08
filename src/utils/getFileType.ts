import { extname, basename } from "node:path";

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

export function getFileType(filename: string) {
  const ext = extname(filename).toLowerCase().replace(".", "");
  const base = basename(filename).toLowerCase();

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
