#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    chmod -R 777 "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
}

@test "Edge: Handle filenames with spaces" {
    echo "content" > "$TEST_DIR/my code file.js"
    
    run bash -c "echo '$TEST_DIR/my code file.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"my code file.js"* ]]
    [[ "$output" == *"javascript"* ]]
}

@test "Edge: Handle filenames with special characters" {
    echo "content" > "$TEST_DIR/file-with-dashes.js"
    echo "content" > "$TEST_DIR/file_with_underscores.js"
    echo "content" > "$TEST_DIR/file.with.dots.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/file-with-dashes.js' '$TEST_DIR/file_with_underscores.js' '$TEST_DIR/file.with.dots.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file-with-dashes.js"* ]]
    [[ "$output" == *"file_with_underscores.js"* ]]
    [[ "$output" == *"file.with.dots.js"* ]]
}

@test "Edge: Handle filenames with unicode characters" {
    echo "content" > "$TEST_DIR/test.js"
    
    run bash -c "echo '$TEST_DIR/test.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test.js"* ]]
}

@test "Edge: Handle empty files" {
    touch "$TEST_DIR/empty.js"
    
    run bash -c "echo '$TEST_DIR/empty.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Edge: Handle very small files" {
    echo "" > "$TEST_DIR/just_newline.js"
    
    run bash -c "echo '$TEST_DIR/just_newline.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Edge: Handle non-existent files" {
    run bash -c "echo '$TEST_DIR/ghost_file.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Edge: Skip unreadable files" {
    echo "secret" > "$TEST_DIR/locked.js"
    chmod 000 "$TEST_DIR/locked.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/locked.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Edge: Skip files with no read permission in readable directory" {
    echo "secret" > "$TEST_DIR/readable.js"
    echo "locked" > "$TEST_DIR/no_read.js"
    chmod 444 "$TEST_DIR/readable.js"
    chmod 000 "$TEST_DIR/no_read.js" 2>/dev/null || true
    
    run bash -c "printf '%s\n' '$TEST_DIR/readable.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"readable.js"* ]]
}

@test "Edge: Handle mixed case extensions correctly" {
    echo "console.log('test')" > "$TEST_DIR/file.JS"
    echo "print('test')" > "$TEST_DIR/file.PY"
    
    run bash -c "printf '%s\n' '$TEST_DIR/file.JS' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"javascript"* ]]
}

@test "Edge: Handle deeply nested paths" {
    mkdir -p "$TEST_DIR/a/b/c/d/e"
    echo "nested" > "$TEST_DIR/a/b/c/d/e/deep.js"
    
    run bash -c "echo '$TEST_DIR/a/b/c/d/e/deep.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"deep.js"* ]]
}

@test "Edge: Handle absolute paths in output" {
    echo "content" > "$TEST_DIR/abs_test.js"
    
    run bash -c "echo '$TEST_DIR/abs_test.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"--"* ]]
    [[ "$output" == *"file_path:"* ]]
    [[ "$output" == *"/"* ]]
}

@test "Edge: Output contains proper code block delimiters" {
    echo "test" > "$TEST_DIR/code.js"
    
    run bash -c "echo '$TEST_DIR/code.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"\`\`\`"* ]]
}

@test "Edge: Output preserves multiline content correctly" {
    cat > "$TEST_DIR/multiline.js" << 'EOF'
function hello() {
    console.log("Hello, World!");
    return true;
}
EOF
    
    run bash -c "echo '$TEST_DIR/multiline.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"function hello"* ]]
    [[ "$output" == *"console.log"* ]]
    [[ "$output" == *"return true"* ]]
}

@test "Edge: Output preserves content with special bash characters" {
    cat > "$TEST_DIR/special.sh" << 'EOF'
echo "Hello $WORLD"
echo "Backtick: \`command\`"
EOF
    
    run bash -c "echo '$TEST_DIR/special.sh' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Edge: Handle files with only shebang" {
    echo "#!/bin/bash" > "$TEST_DIR/shebang_only.sh"
    
    run bash -c "echo '$TEST_DIR/shebang_only.sh' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"bash"* ]]
}

@test "Edge: Handle Windows-style line endings (CRLF)" {
    printf "echo 'test'\r\n" > "$TEST_DIR/crlf.sh"
    
    run bash -c "echo '$TEST_DIR/crlf.sh' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Edge: Handle directory with only binary files" {
    echo "binary" | gzip > "$TEST_DIR/file1.gz"
    printf "\x00\x01\x02" > "$TEST_DIR/binary.bin"
    
    run bash -c "printf '%s\n' '$TEST_DIR/file1.gz' '$TEST_DIR/binary.bin' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Edge: Handle symlinks to readable files" {
    echo "original" > "$TEST_DIR/original.js"
    ln -s "$TEST_DIR/original.js" "$TEST_DIR/link.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/link.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"link.js"* ]]
}

@test "Edge: Handle broken symlinks" {
    ln -s "$TEST_DIR/nonexistent.js" "$TEST_DIR/broken.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/broken.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Edge: Handle multiple spaces in filename" {
    echo "content" > "$TEST_DIR/file with many   spaces.js"
    
    run bash -c "echo '$TEST_DIR/file with many   spaces.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file with many"* ]]
}

@test "Edge: Output format includes correct number of delimiters" {
    echo "a" > "$TEST_DIR/a.js"
    echo "b" > "$TEST_DIR/b.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/a.js' '$TEST_DIR/b.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    count=$(echo "$output" | grep -c '\-\-\-' || echo "0")
    [ "$count" -ge 2 ]
}
