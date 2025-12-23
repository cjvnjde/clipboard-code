#!/usr/bin/env bats

setup() {
    # 1. Define the path to the script (One level up from the 'test' directory)
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    
    # 2. Create a temporary sandbox directory for file operations
    export TEST_DIR="$(mktemp -d)"
    
    # 3. Create dummy files with distinct content
    # We add content so they aren't skipped as empty files
    echo "console.log('root');" > "$TEST_DIR/root_file.js"
    echo "print('python')" > "$TEST_DIR/root_python.py"
    
    # 4. Create a subdirectory with a file
    mkdir "$TEST_DIR/subdir"
    echo "func main() {}" > "$TEST_DIR/subdir/nested.go"
}

teardown() {
    # Clean up the temporary directory after each test
    rm -rf "$TEST_DIR"
}

# --- TEST CASE 1: Default Directory Scan ---
@test "Group 1: Scan current directory (default behavior)" {
    # Move into the test dir so "." refers to it
    cd "$TEST_DIR"
    
    run bash "$SCRIPT_PATH"
    
    [ "$status" -eq 0 ]
    # Output should contain the file path header for the JS file
    [[ "$output" == *"root_file.js"* ]]
    [[ "$output" == *"nested.go"* ]]
}

# --- TEST CASE 2: Root Flag (-r) ---
@test "Group 1: Scan specific directory using -r flag" {
    # Run from outside, pointing to the test dir
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"root_file.js"* ]]
    [[ "$output" == *"nested.go"* ]]
}

# --- TEST CASE 3: Root Flag (--root) ---
@test "Group 1: Scan specific directory using --root flag" {
    run bash "$SCRIPT_PATH" --root "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"root_file.js"* ]]
    [[ "$output" == *"nested.go"* ]]
}

# --- TEST CASE 4: Direct File Arguments ---
@test "Group 1: Process specific files passed as arguments" {
    run bash "$SCRIPT_PATH" "$TEST_DIR/root_file.js" "$TEST_DIR/subdir/nested.go"
    
    [ "$status" -eq 0 ]
    # Should include these two
    [[ "$output" == *"root_file.js"* ]]
    [[ "$output" == *"nested.go"* ]]
    # Should NOT include the python file which we didn't ask for
    [[ "$output" != *"root_python.py"* ]]
}

# --- TEST CASE 5: Stdin Piping ---
@test "Group 1: Process file list via Stdin (Pipe)" {
    # Use 'find' to generate list and pipe it to script
    # We pipe strictly the python file to ensure it accepts stdin
    run bash -c "echo '$TEST_DIR/root_python.py' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"root_python.py"* ]]
    [[ "$output" != *"root_file.js"* ]]
}

# --- TEST CASE 6: Mixed Directory and File Args ---
# Testing the 'case *)' logic where an arg is treated as DIR if no flags are used
@test "Group 1: Handle directory path passed as a positional argument" {
    run bash "$SCRIPT_PATH" "$TEST_DIR/subdir"
    
    [ "$status" -eq 0 ]
    # Should find the nested file
    [[ "$output" == *"nested.go"* ]]
    # Should NOT find the root file
    [[ "$output" != *"root_file.js"* ]]
}
