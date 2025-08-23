# clipboard-code

This script formats the content of files into Markdown code blocks with YAML front matter, making it easy to copy and paste code snippets with their file paths.

## Installation

1. Make sure the script is executable:

    ```bash
    chmod +x clipboard-code.sh
    ```

2. Create a symbolic link to the script in a directory that is in your system's `PATH` (e.g., `~/.local/bin` or `/usr/local/bin`) to make it accessible from anywhere without the `.sh` extension:

    ```bash
    ln -sr ./clipboard-code.sh ~/.local/bin/clipboard-code
    ```

3. Place the script in a directory that is in your system's `PATH` (e.g., `/usr/local/bin`) to make it accessible from anywhere.

## Usage

You can use the `clipboard-code` script in several ways:

### 1. Process a Single File

To process a single file, provide the file path as an argument:

```bash
clipboard-code /path/to/your/file.js
```

This will output the content of `file.js` in a Markdown code block with its file path in the front matter.

### 2. Process a Directory

To process all files in a directory, provide the directory path:

```bash
clipboard-code /path/to/your/project
```

The script will recursively find all text files in the directory and generate a formatted output for each.

### 3. Piping from `find` or `ls`

You can pipe the output of other commands like `find` or `ls` to `clipboard-code`:

```bash
find . -name "*.py" | clipboard-code
```

This will process all Python files in the current directory.

```bash
ls -d /path/to/your/project/* | clipboard-code
```

This will process all files and directories in the specified path.

### 4. Interactive selection with fzf

You can use `fzf` to interactively select files and then process them with `clipboard-code`:

```bash
fzf --multi | clipboard-code
```

This command opens `fzf`, allowing you to select multiple files. The selected file paths are then piped to `clipboard-code` for processing.

## Saving the Output

### Saving to a File

You can save the output to a file using the `>>` redirect operator:

```bash
clipboard-code /path/to/your/project >> project-code.md
```

This will append the formatted code of all files in `/path/to/your/project` to `project-code.md`.

### Saving to Clipboard

You can pipe the output directly to your clipboard manager.

#### Linux (Wayland)

If you are using Wayland, you can use `wl-copy`:

```bash
clipboard-code /path/to/your/file.js | wl-copy
```

#### Linux (X11)

For X11-based systems, you can use `xclip`:

```bash
clipboard-code /path/to/your/file.js | xclip -selection clipboard
```

#### macOS

On macOS, you can use `pbcopy`:

```bash
clipboard-code /path/to/your/file.js | pbcopy
```

## Examples

### Example 1: Process a Python file

```bash
clipboard-code my_script.py
```

**Output:**

``````yaml
---
file_path: "my_script.py"
---

```python
# Contents of my_script.py
print("Hello, world!")
```

``````

## Supported Languages

The script automatically detects the language for syntax highlighting based on the file extension. It supports a wide range of common programming and markup languages, including:

- JavaScript (`.js`, `.jsx`)
- TypeScript (`.ts`, `.tsx`)
- Python (`.py`)
- Ruby (`.rb`)
- Go (`.go`)
- Rust (`.rs`)
- Java (`.java`)
- C/C++ (`.c`, `.cpp`, `.h`)
- C# (`.cs`)
- PHP (`.php`)
- Swift (`.swift`)
- Kotlin (`.kt`)
- HTML (`.html`)
- CSS/SCSS (`.css`, `.scss`)
- JSON (`.json`)
- YAML (`.yaml`, `.yml`)
- Markdown (`.md`)
- And many more.