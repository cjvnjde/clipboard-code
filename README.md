# clipboard-code

This script formats the content of files into Markdown code blocks with YAML front matter, making it easy to copy and paste code snippets with their file paths.

## Installation

1. Make sure the script is executable:

    ```bash
    chmod +x clipboard-code
    ```

2. Place the script in a directory that is in your system's `PATH` (e.g., `/usr/local/bin`) to make it accessible from anywhere.

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

### 4. Piping from `find` or `ls`

You can pipe the output of other commands like `find` or `ls` to `clipboard-code`:

```bash
find . -name "*.py" | clipboard-code
```

This will process all Python files in the current directory.

```bash
ls -d /path/to/your/project/* | clipboard-code
```

This will process all files and directories in the specified path.

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
