# clipboard-code

Format files into Markdown code blocks with YAML front matter.

## Quick Examples

```bash
# Single file
clipboard-code script.py

# All files in directory
clipboard-code /path/to/project

# From pipe (find, ls, fzf)
find . -name "*.go" | clipboard-code
fzf | clipboard-code

# Save to file
clipboard-code src/ >> project.md

# Copy to clipboard
clipboard-code main.js | pbcopy      # macOS
clipboard-code main.js | xclip -selection clipboard  # Linux X11
clipboard-code main.js | wl-copy     # Linux Wayland
```

## Input Methods

### Argument: Single File
```bash
clipboard-code myfile.js
```

### Argument: Directory
```bash
clipboard-code /path/to/project   # recursive
```

### Pipe: File List
```bash
echo "file1.py" | clipboard-code
printf "file1.js\nfile2.py" | clipboard-code
```

### Here-String/Doc
```bash
clipboard-code <<< "script.sh"
clipboard-code <<EOF
file1.py
file2.js
EOF
```

## Workflow Examples

### Select files interactively with fzf
```bash
# Multi-select files then copy to clipboard
fzf --multi | clipboard-code | pbcopy

# Filter by extension first
find . -name "*.py" | fzf --multi | clipboard-code
```

### Git workflows
```bash
# Show changed files in current branch
git diff --name-only | clipboard-code

# Show staged files
git diff --cached --name-only | clipboard-code

# All Python files changed since main
git diff main...HEAD --name-only | grep '\.py$' | clipboard-code

# Files from specific commit
git show --name-only --pretty=format: COMMIT | clipboard-code
```

### Code review / sharing
```bash
# Export entire src directory to file
clipboard-code src/ > codebase.md

# Export only modified Go files
git status --porcelain | awk '{print $2}' | grep '\.go$' | clipboard-code

# Create documentation from config files
find . -name "*.config" -o -name "*.conf" | clipboard-code > configs.md
```

### Multi-source combinations
```bash
# Merge multiple directories
(echo dir1/file1.py; echo dir2/file2.js) | clipboard-code

# Combine find results with specific files
find . -name "*.ts" | clipboard-code && echo "extra.py" | clipboard-code > combined.md

# From git ls-files
git ls-files '*.json' | clipboard-code
```

### Output variations
```bash
# Append to existing file
clipboard-code new_feature/ >> README.md

# Only file paths (extract from output)
clipboard-code src/ | grep 'file_path:' | cut -d'"' -f2

# Count files processed
clipboard-code project/ | grep -c 'file_path:'

# Preview without saving
clipboard-code app.py | head -20
```

### IDE / Editor integration
```bash
# Vim/Neovim: selected lines to clipboard
:'<,'>w !clipboard-code | pbcopy

# VSCode terminal: copy current file
code --locale en . && clipboard-code ${PWD}/src/App.tsx | pbcopy
```

### Filter by file characteristics
```bash
# Only recently modified files (last 7 days)
find . -mtime -7 -name "*.py" | clipboard-code

# Files larger than 1KB
find . -size +1k -name "*.js" | clipboard-code

# Top-level config files only
ls *.json *.yaml *.toml 2>/dev/null | clipboard-code

# Hidden config files
find . -maxdepth 1 -name "\.*" | clipboard-code
```

### Documentation generation
```bash
# Generate API docs from Python
find . -name "api*.py" | clipboard-code > api_reference.md

# Database schema from SQL files
find . -name "*.sql" | clipboard-code > schema.md

# Component library from Vue/React files
find . -path "*/components/*" -name "*.vue" | clipboard-code > components.md
```

## Examples by Language

```bash
clipboard-code main.go          # go
clipboard-code lib.rs           # rust
clipboard-code index.tsx        # tsx
clipboard-code App.vue          # vue
clipboard-code config.yaml      # yaml
clipboard-code Dockerfile       # dockerfile
clipboard-code Makefile         # makefile
clipboard-code query.sql        # sql
clipboard-code styles.scss      # scss
clipboard-code component.jsx    # javascript react
clipboard-code service.rb       # ruby
clipboard-code script.php       # php
clipboard-code Hello.java       # java
clipboard-code main.c           # c
clipboard-code header.hpp       # c++
clipboard-code program.cs       # c#
clipboard-code solution.swift   # swift
clipboard-code main.kt          # kotlin
clipboard-code main.dart        # dart
clipboard-code hello.hs         # haskell
clipboard-code mix.exs          # elixir
clipboard-code hello.ex         # elixir module
clipboard-code hello.erl        # erlang
clipboard-code hello.clj        # clojure
clipboard-code main.lua         # lua
clipboard-code hello.pl         # perl
clipboard-code hello.nim        # nim
clipboard-code build.zig        # zig
clipboard-code main.tf          # terraform
clipboard-code docker-compose.yml  # yaml
clipboard-code .env.example     # dotenv (text detected)
```

## Filtering

Only processes text files (skips binary):
- Code files: `.py`, `.js`, `.ts`, `.go`, `.rs`, etc.
- Config files: `.json`, `.yaml`, `.toml`, `.ini`, `.conf`
- Markup: `.html`, `.xml`, `.md`, `.vue`, `.svelte`
- Scripts: `.sh`, `.bash`, `.py` (via shebang detection)

Rejected: images, PDFs, archives, compiled binaries

## Shebang Detection

Scripts without extensions are detected by shebang:
```bash
echo '#!/bin/bash\necho hi' > runner
clipboard-code runner           # → bash

echo '#!/usr/bin/env python3\nprint(1)' > checker
clipboard-code checker          # → python
```

## Output Format

```yaml
---
file_path: "src/main.py"
---

```python
def main():
    print("hello")
```
```

## Install

```bash
chmod +x clipboard-code.sh
ln -sr clipboard-code.sh ~/.local/bin/clipboard-code
```
