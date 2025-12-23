#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    chmod -R 777 "$TEST_DIR" # Ensure we can delete readable files
    rm -rf "$TEST_DIR"
}

@test "Group 5: Handle filenames with spaces" {
    echo "content" > "$TEST_DIR/my code file.js"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"my code file.js"* ]]
    [[ "$output" == *"\`\`\`javascript"* ]]
}

@test "Group 5: Skip empty files (MIME inode/x-empty)" {
    touch "$TEST_DIR/empty.js"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    # The script looks for ^text/ or ^application/...
    # Empty files are usually 'inode/x-empty', so they should be skipped.
    [[ "$output" != *"empty.js"* ]]
}

@test "Group 5: Handle non-existent files gracefully" {
    run bash "$SCRIPT_PATH" "$TEST_DIR/ghost_file.js"
    
    # Should print to stderr but not crash
    [[ "$output" == *"Skipping"* ]]
    [[ "$output" == *"not found or not readable"* ]]
}

@test "Group 5: Skip unreadable files" {
    echo "secret" > "$TEST_DIR/locked.js"
    chmod 000 "$TEST_DIR/locked.js"
    
    run bash "$SCRIPT_PATH" "$TEST_DIR/locked.js"
    
    # Should print error to stderr and skip
    [[ "$output" == *"Skipping"* ]]
    [[ "$output" != *"\`\`\`javascript"* ]]
}
