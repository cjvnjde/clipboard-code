#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Input: Process file list via Stdin (Pipe)" {
    echo "content" > "$TEST_DIR/root_python.py"
    run bash -c "echo '$TEST_DIR/root_python.py' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"root_python.py"* ]]
}

@test "Input: Handle empty stdin gracefully" {
    run bash -c "echo -n '' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == "" ]]
}

@test "Input: Handle stdin with empty lines" {
    echo "content" > "$TEST_DIR/file.js"
    run bash -c "echo -e '\n\n$TEST_DIR/file.js\n\n' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Input: Handle stdin with duplicate entries" {
    echo "content" > "$TEST_DIR/dup.js"
    
    run bash -c "echo -e '$TEST_DIR/dup.js\n$TEST_DIR/dup.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Input: Process multiple files from stdin" {
    echo "js" > "$TEST_DIR/file1.js"
    echo "py" > "$TEST_DIR/file2.py"
    
    run bash -c "echo -e '$TEST_DIR/file1.js\n$TEST_DIR/file2.py' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file1.js"* ]]
    [[ "$output" == *"file2.py"* ]]
}

@test "Input: Handle here-string stdin input" {
    echo "content" > "$TEST_DIR/file.js"
    
    run bash "$SCRIPT_PATH" <<< "$TEST_DIR/file.js"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Input: Handle here-doc stdin input" {
    echo "content" > "$TEST_DIR/file.js"
    
    run bash "$SCRIPT_PATH" <<EOF
$TEST_DIR/file.js
EOF
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Input: Process stdin with paths containing spaces" {
    echo "content" > "$TEST_DIR/my file.js"
    
    run bash -c "echo '$TEST_DIR/my file.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"my file.js"* ]]
}

@test "Input: Handle non-ASCII path in stdin" {
    mkdir "$TEST_DIR/тест"
    echo "test" > "$TEST_DIR/тест/file.js"
    
    run bash -c "echo '$TEST_DIR/тест/file.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Input: Stdin input with relative paths" {
    echo "content" > "$TEST_DIR/rel.js"
    cd "$TEST_DIR"
    
    run bash -c "echo './rel.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"rel.js"* ]]
}

@test "Input: Mixed absolute and relative paths in stdin" {
    echo "content" > "$TEST_DIR/abs.js"
    echo "content" > "$TEST_DIR/rel.js"
    cd "$TEST_DIR"
    
    run bash -c "echo -e '$TEST_DIR/abs.js\n./rel.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Input: Very long path in stdin" {
    long_dir="$TEST_DIR"
    for i in $(seq 1 20); do
        long_dir="$long_dir/dir_$i"
        mkdir -p "$long_dir"
    done
    echo "test" > "$long_dir/file.js"
    
    run bash -c "echo '$long_dir/file.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Input: Stdin with many files" {
    for i in $(seq 1 20); do
        echo "content" > "$TEST_DIR/file_$i.js"
    done
    
    run bash -c "printf '%s\n' $TEST_DIR/file_{1..20}.js | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file_1.js"* ]]
    [[ "$output" == *"file_20.js"* ]]
}

@test "Input: Directory path via stdin is treated as file path" {
    mkdir "$TEST_DIR/subdir"
    echo "test" > "$TEST_DIR/subdir/file.js"
    
    run bash -c "echo '$TEST_DIR/subdir' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Input: Non-existent file in stdin" {
    run bash -c "echo '$TEST_DIR/nonexistent.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Input: Stdin with only whitespace lines" {
    run bash -c "echo -e '   \n\t\n  ' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == "" ]]
}

@test "Input: Symlink in stdin" {
    echo "original" > "$TEST_DIR/original.js"
    ln -s "$TEST_DIR/original.js" "$TEST_DIR/link.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/link.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"link.js"* ]]
}

@test "Input: Broken symlink in stdin" {
    ln -s "$TEST_DIR/nonexistent.js" "$TEST_DIR/broken.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/broken.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Input: Unicode content in file via stdin" {
    echo "привет" > "$TEST_DIR/unicode.js"
    
    run bash -c "echo '$TEST_DIR/unicode.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"привет"* ]]
}

@test "Input: Multiline content via stdin" {
    cat > "$TEST_DIR/multiline.js" << 'EOF'
function test() {
    return true;
}
EOF
    
    run bash -c "echo '$TEST_DIR/multiline.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"function test"* ]]
    [[ "$output" == *"return true"* ]]
}
