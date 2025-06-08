# clipboard-code

**clipboard-code** is a terminal tool that lets you interactively select files and folders from your project, then copy their contents to your clipboard in a markdown-friendly format for easy sharing with AI chats, documentation, or teammates.

## Features

* **Interactive file/folder selection**: Navigate your project structure using arrow keys and checkboxes, all in your terminal.
* **Select All**: Instantly select or deselect all files/folders.
* **Recursive selection**: Selecting a folder selects/deselects all its children.
* **Smart language detection**: Outputs files in markdown code blocks with the correct language (e.g., `typescript`, `json`, `bash`, etc.).
* **Markdown export**: The clipboard output is ready to paste into AI chats or markdown docs. Example format:

  ````markdown
  src/index.ts
  ```typescript
  // file content here
  ```

  public/style.css
  ```css
  /* file content here */
  ```
  ````

* **Wayland clipboard support**: Uses `wl-copy` for clipboard interaction (Wayland only).

## Requirements

* **Bun** runtime ([Get Bun](https://bun.sh))
* **Wayland** session (uses `wl-copy` to copy to clipboard)

## Installation

Clone this repository and install dependencies:

```bash
git clone git@github.com:cjvnjde/clipboard-code.git
cd clipboard-code
bun install
```

## Usage

Run the file picker:

```bash
bun run index.ts
```

* Use **Up/Down** arrow keys to move the cursor
* **Space** toggles selection (on a file/folder or on 'Select All')
* **Enter** copies selected files' content to clipboard in markdown format and exits
* **Ctrl+C** to exit without copying

Example session:

```text
> [x] Select All
  [x] src/
    [x] index.ts
  [ ] package.json
  [ ] README.md

Use arrows to move, [space] to toggle, [enter] to finish.
```

## Output Format

Selected files are copied in this markdown structure:

````
<filepath>
```<filetype>
<filecontent>
```
````

* `filetype` is auto-detected for syntax highlighting (supports js, ts, json, css, sh, py, etc.)
* Directories are skipped (only file content is copied)

## Supported Filetypes

Most common source and config file types are detected. If not, content will be marked as `text`.

## Building (Optional)

Compile to a standalone binary (Linux x64/Wayland only):

```bash
bun run compile
# output: out/clipboard-code
````

## License

MIT
