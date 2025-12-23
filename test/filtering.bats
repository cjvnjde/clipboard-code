#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Group 2: Accept specific whitelisted extensions (ts, rs, go, css)" {
    echo "x" > "$TEST_DIR/test.ts"
    echo "x" > "$TEST_DIR/test.rs"
    echo "x" > "$TEST_DIR/test.go"
    echo "x" > "$TEST_DIR/test.css"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test.ts"* ]]
    [[ "$output" == *"test.rs"* ]]
    [[ "$output" == *"test.go"* ]]
    [[ "$output" == *"test.css"* ]]
}

@test "Group 2: Reject binary files" {
    # Create a pseudo-binary file (gzip)
    echo "test" | gzip > "$TEST_DIR/binary.gz"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" != *"binary.gz"* ]]
}

@test "Group 2: Accept unknown extensions if MIME type is text/plain" {
    # .weird is not in the whitelist, but 'file' detects it as text
    echo "Some plain text content" > "$TEST_DIR/README.weird"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"README.weird"* ]]
}

@test "Group 2: Include dotfiles (hidden files)" {
    echo "config=true" > "$TEST_DIR/.env"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file_path: \"$TEST_DIR/.env\""* ]]
}
