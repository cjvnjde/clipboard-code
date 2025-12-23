#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
    echo "unique content" > "$TEST_DIR/uniq.txt"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Group 4: Deduplicate identical input files" {
    # Pass the same file twice as arguments
    run bash "$SCRIPT_PATH" "$TEST_DIR/uniq.txt" "$TEST_DIR/uniq.txt"
    
    [ "$status" -eq 0 ]
    
    # Count occurrences of the file header in output
    # Grep -c counts lines. We expect 1 line matching "file_path: ...uniq.txt"
    count=$(echo "$output" | grep -c "file_path: \"$TEST_DIR/uniq.txt\"")
    [ "$count" -eq 1 ]
}

@test "Group 4: Deduplicate mixed relative and absolute paths" {
    cd "$TEST_DIR"
    abs_path="$TEST_DIR/uniq.txt"
    rel_path="./uniq.txt"
    
    run bash "$SCRIPT_PATH" "$abs_path" "$rel_path"
    
    [ "$status" -eq 0 ]
    count=$(echo "$output" | grep -c "file_path:")
    [ "$count" -eq 1 ]
}

@test "Group 4: Recursively find files in subdirectories" {
    mkdir -p "$TEST_DIR/a/b/c"
    echo "deep" > "$TEST_DIR/a/b/c/deep.js"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [[ "$output" == *"deep.js"* ]]
}
