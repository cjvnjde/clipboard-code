#!/bin/bash

DIR="."

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--root)
      DIR="$2"
      shift 2
      ;;
    *)
      DIR="$1"
      shift
      ;;
  esac
done

processed_files_list=""

expand_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    find "$path" -type f
  elif [[ -f "$path" ]]; then
    echo "$path"
  fi
}

if [ -t 0 ]; then
  INPUT_SOURCE="find \"$DIR\" -type f"
else
  INPUT_SOURCE="while IFS= read -r line; do expand_path \"\$line\"; done"
fi

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  
  abs_path=$(realpath "$f" 2>/dev/null || echo "$f")
  
  if [[ "$processed_files_list" == *"|$abs_path|"* ]]; then
    continue
  fi
  
  processed_files_list="${processed_files_list}|$abs_path|"
  
  if [[ ! -f "$f" ]] || [[ ! -r "$f" ]]; then
    echo "Skipping $f (not found or not readable)" >&2
    continue
  fi
  
  MIME_TYPE=$(file --mime-type "$f" | cut -d: -f2 | tr -d ' ')
  if [[ "$MIME_TYPE" =~ ^text/ ]] || \
     [[ "$MIME_TYPE" =~ ^application/(json|javascript|xml|yaml|x-yaml|x-sh|x-shellscript) ]] || \
     [[ "$MIME_TYPE" =~ ^application/(x-httpd-php|x-ruby|x-python) ]] || \
     [[ "$f" =~ \.(tsx?|jsx?|py|rb|go|rs|java|c|cpp|cc|cxx|h|hpp|cs|php|swift|kt|dart|vue|svelte|html|css|scss|sass|less|json|xml|ya?ml|toml|ini|conf|md|sql|r|scala|clj|hs|ex|exs|erl|lua|pl|vim|sh|bash|zsh|fish)$ ]]; then
    
    FILENAME=$(basename "$f")
    FILE_EXT="${FILENAME##*.}"
    
    if [[ "$FILE_EXT" != "$FILENAME" ]] && [[ -n "$FILE_EXT" ]]; then
        case "$FILE_EXT" in
            tsx|jsx) CODE_LANG="tsx" ;;
            ts) CODE_LANG="typescript" ;;
            js) CODE_LANG="javascript" ;;
            py) CODE_LANG="python" ;;
            sh) CODE_LANG="bash" ;;
            rb) CODE_LANG="ruby" ;;
            go) CODE_LANG="go" ;;
            rs) CODE_LANG="rust" ;;
            java) CODE_LANG="java" ;;
            cpp|cc|cxx) CODE_LANG="cpp" ;;
            c) CODE_LANG="c" ;;
            h|hpp) CODE_LANG="c" ;;
            cs) CODE_LANG="csharp" ;;
            php) CODE_LANG="php" ;;
            swift) CODE_LANG="swift" ;;
            kt) CODE_LANG="kotlin" ;;
            dart) CODE_LANG="dart" ;;
            vue) CODE_LANG="vue" ;;
            svelte) CODE_LANG="svelte" ;;
            html) CODE_LANG="html" ;;
            css) CODE_LANG="css" ;;
            scss|sass) CODE_LANG="scss" ;;
            less) CODE_LANG="less" ;;
            json) CODE_LANG="json" ;;
            xml) CODE_LANG="xml" ;;
            yaml|yml) CODE_LANG="yaml" ;;
            toml) CODE_LANG="toml" ;;
            ini) CODE_LANG="ini" ;;
            conf) CODE_LANG="conf" ;;
            md) CODE_LANG="markdown" ;;
            sql) CODE_LANG="sql" ;;
            r) CODE_LANG="r" ;;
            scala) CODE_LANG="scala" ;;
            clj) CODE_LANG="clojure" ;;
            hs) CODE_LANG="haskell" ;;
            ex|exs) CODE_LANG="elixir" ;;
            erl) CODE_LANG="erlang" ;;
            lua) CODE_LANG="lua" ;;
            pl) CODE_LANG="perl" ;;
            vim) CODE_LANG="vim" ;;
            *) CODE_LANG="$FILE_EXT" ;;
        esac
    else
        FIRST_LINE=$(head -n1 "$f" 2>/dev/null)
        if [[ "$FIRST_LINE" =~ ^#!.*bash ]] || [[ "$FIRST_LINE" =~ ^#!.*sh ]]; then
            CODE_LANG="bash"
        elif [[ "$FIRST_LINE" =~ ^#!.*python ]]; then
            CODE_LANG="python"
        else
            CODE_LANG=""
        fi
    fi
    
    OUTPUT="${OUTPUT}---\n"
    OUTPUT="${OUTPUT}file_path: \"$f\"\n"
    OUTPUT="${OUTPUT}---\n\n"
    
    OUTPUT="$OUTPUT\`\`\`${CODE_LANG}\n"
    OUTPUT="$OUTPUT$(cat "$f")\n"
    OUTPUT="$OUTPUT\`\`\`\n\n"
  fi
done < <(eval "$INPUT_SOURCE")

printf "%b" "$OUTPUT"
