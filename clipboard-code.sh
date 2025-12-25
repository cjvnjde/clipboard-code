#!/usr/bin/env bash

set -euo pipefail

MAX_FILE_SIZE_MB=10

DIR="."
SHOW_HELP=false

print_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [DIRECTORY|FILE]

Collect code files from a directory or stdin and format for clipboard.

OPTIONS:
  -r, --root DIR    Root directory to search (default: current directory)
  -h, --help        Show this help message

INPUT:
  - If stdin is a pipe/redirect, reads file/directory paths from stdin
  - Otherwise, finds all files in the specified directory

EXAMPLES:
  $(basename "$0") .
  $(basename "$0") --root /path/to/project
  find . -name "*.py" | $(basename "$0")
EOF
}

check_dependencies() {
  local missing=()
  for cmd in file realpath; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing required commands: ${missing[*]}" >&2
    exit 1
  fi
}

is_text_file() {
  local file="$1"
  local mime_type file_size

  [[ -f "$file" ]] && [[ -r "$file" ]] || return 1

  # Get file size
  file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)

  mime_type=$(file -L --mime-type -b "$file" 2>/dev/null) || return 1

  # Empty files are not useful
  [[ "$mime_type" == "inode/x-empty" ]] && return 1

  # Accept text files
  if [[ "$mime_type" =~ ^text/ ]]; then
    return 0
  fi

  # On some systems, small text files might be detected as application/octet-stream
  # If file is small (< 1KB) and contains only printable characters, treat as text
  if [[ "$mime_type" == "application/octet-stream" ]] && [[ $file_size -lt 1024 ]]; then
    if LC_ALL=C grep -q '^[[:print:][:space:]]*$' "$file" 2>/dev/null; then
      return 0
    fi
  fi

  case "$mime_type" in
    application/json|application/javascript|application/xml|application/yaml)
      return 0
      ;;
    application/x-shellscript|application/x-sh)
      return 0
      ;;
    application/x-httpd-php|application/x-ruby|application/x-python)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

get_code_language() {
  local file="$1"
  local filename ext ext_lower first_line code_lang=""

  filename=$(basename "$file")

  if [[ "$filename" == *.* ]]; then
    ext="${filename##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$ext_lower" in
      tsx|jsx) code_lang="tsx" ;;
      ts) code_lang="typescript" ;;
      js) code_lang="javascript" ;;
      py) code_lang="python" ;;
      sh) code_lang="bash" ;;
      rb) code_lang="ruby" ;;
      go) code_lang="go" ;;
      rs) code_lang="rust" ;;
      java) code_lang="java" ;;
      cpp|cc|cxx) code_lang="cpp" ;;
      c) code_lang="c" ;;
      h|hpp) code_lang="c" ;;
      cs) code_lang="csharp" ;;
      php) code_lang="php" ;;
      swift) code_lang="swift" ;;
      kt) code_lang="kotlin" ;;
      dart) code_lang="dart" ;;
      vue) code_lang="vue" ;;
      svelte) code_lang="svelte" ;;
      html) code_lang="html" ;;
      css) code_lang="css" ;;
      scss|sass) code_lang="scss" ;;
      less) code_lang="less" ;;
      json) code_lang="json" ;;
      xml) code_lang="xml" ;;
      yaml|yml) code_lang="yaml" ;;
      toml) code_lang="toml" ;;
      ini) code_lang="ini" ;;
      conf) code_lang="conf" ;;
      md) code_lang="markdown" ;;
      sql) code_lang="sql" ;;
      r) code_lang="r" ;;
      scala) code_lang="scala" ;;
      clj) code_lang="clojure" ;;
      hs) code_lang="haskell" ;;
      ex|exs) code_lang="elixir" ;;
      erl) code_lang="erlang" ;;
      lua) code_lang="lua" ;;
      pl) code_lang="perl" ;;
      vim) code_lang="vim" ;;
      *) code_lang="$ext" ;;
    esac
  else
    first_line=$(head -n1 "$file" 2>/dev/null || echo "")

    if [[ "$first_line" =~ ^#!.*/(bash|sh) ]]; then
      code_lang="bash"
    elif [[ "$first_line" =~ ^#!.*python ]]; then
      code_lang="python"
    elif [[ -n "$first_line" && "$first_line" =~ ^#! ]]; then
      code_lang="bash"
    fi
  fi

  echo "$code_lang"
}

should_include_file() {
  local file="$1"
  local filename ext ext_lower first_line

  filename=$(basename "$file")

  # Always try to include hidden files (dotfiles)
  # They'll still be filtered by is_text_file if they're binary
  if [[ "$filename" == .* ]]; then
    # Check if it's a text file, but be lenient
    if is_text_file "$file"; then
      return 0
    fi
    # Even if is_text_file fails, try to include common config files
    case "$filename" in
      .env|.secret|.gitignore|.dockerignore|.editorconfig|.eslintrc|.prettierrc|.babelrc|.npmrc|.yarnrc)
        return 0
        ;;
    esac
  fi

  if [[ "$filename" == *.* ]]; then
    ext="${filename##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$ext_lower" in
      ts|tsx|jsx|js|py|rb|go|rs|java|c|cpp|cc|cxx|h|hpp|cs|php|swift|kt|dart|vue|svelte|html|css|scss|sass|less|json|xml|ya?ml|toml|ini|conf|md|sql|r|scala|clj|hs|ex|exs|erl|lua|pl|vim|sh|bash|zsh|fish|mjs|env)
        return 0
        ;;
    esac
  fi

  first_line=$(head -n1 "$file" 2>/dev/null || echo "")
  if [[ "$first_line" =~ ^#! ]]; then
    return 0
  fi

  if is_text_file "$file"; then
    return 0
  fi

  return 1
}

expand_path() {
  local path="$1"

  if [[ -d "$path" ]]; then
    find "$path" -type f 2>/dev/null
  elif [[ -f "$path" ]]; then
    echo "$path"
  fi
}

process_files() {
  local -a output_lines=()
  local processed_paths=""

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue

    local resolved_path
    resolved_path=$(realpath "$f" 2>/dev/null || echo "$f")

    if [[ " $processed_paths " == *" $resolved_path "* ]]; then
      continue
    fi
    processed_paths="${processed_paths}${resolved_path} "

    if [[ ! -f "$f" ]]; then
      echo "Skipping $f (not a file)" >&2
      continue
    fi

    if [[ ! -r "$f" ]]; then
      echo "Skipping $f (not readable)" >&2
      continue
    fi

    local file_size
    file_size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo 0)

    if [[ $file_size -gt $((MAX_FILE_SIZE_MB * 1024 * 1024)) ]]; then
      echo "Skipping $f (exceeds ${MAX_FILE_SIZE_MB}MB limit)" >&2
      continue
    fi

    if ! is_text_file "$f"; then
      continue
    fi

    if ! should_include_file "$f"; then
      continue
    fi

    local code_lang output_path
    code_lang=$(get_code_language "$f")
    output_path="$f"

    output_lines+=("---")
    output_lines+=("file_path: \"$output_path\"")
    output_lines+=("---")
    output_lines+=("")
    output_lines+=("\`\`\`${code_lang}")
    output_lines+=("$(cat "$f")")
    output_lines+=("\`\`\`")
    output_lines+=("")
  done

  printf '%s\n' "${output_lines[@]:-}"
}

check_dependencies

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--root)
      if [[ -z "${2:-}" ]]; then
        echo "Error: $1 requires a directory argument" >&2
        exit 1
      fi
      DIR="$2"
      shift 2
      ;;
    -h|--help)
      SHOW_HELP=true
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      DIR="$1"
      shift
      ;;
  esac
done

if [[ "$SHOW_HELP" == true ]]; then
  print_help
  exit 0
fi

if [[ -p /dev/stdin ]]; then
  while IFS= read -r line; do
    expand_path "$line"
  done | process_files
else
  if [[ ! -e "$DIR" ]]; then
    echo "Error: Path does not exist: $DIR" >&2
    exit 1
  fi

  expand_path "$DIR" | process_files
fi
