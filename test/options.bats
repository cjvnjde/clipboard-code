#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Help: Display help with -h flag" {
    run bash "$SCRIPT_PATH" -h

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"OPTIONS"* ]]
}

@test "Help: Display help with --help flag" {
    run bash "$SCRIPT_PATH" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"-r, --root"* ]]
}

@test "Help: Help output contains examples" {
    run bash "$SCRIPT_PATH" -h

    [ "$status" -eq 0 ]
    [[ "$output" == *"EXAMPLES"* ]]
}

@test "Root: -r flag requires directory argument" {
    run bash "$SCRIPT_PATH" -r 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"requires"* ]]
}

@test "Root: --root flag requires directory argument" {
    run bash "$SCRIPT_PATH" --root 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"requires"* ]]
}

@test "Root: -r flag with empty directory" {
    mkdir -p "$TEST_DIR/empty"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/empty"

    [ "$status" -eq 0 ]
}

@test "Root: Unknown option shows error" {
    run bash "$SCRIPT_PATH" -x 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "Size: Skip files exceeding 10MB limit" {
    head -c $((11 * 1024 * 1024)) < /dev/zero | tr '\0' 'x' > "$TEST_DIR/large.js"

    run bash -c "echo '$TEST_DIR/large.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" != *"file_path:"*"large.js"* ]]
    [[ "$output" == *"exceeds"* ]]
}

@test "Size: Accept files at exactly 10MB limit" {
    head -c $((10 * 1024 * 1024)) < /dev/zero | tr '\0' 'x' > "$TEST_DIR/tenmb.js"

    run bash -c "echo '$TEST_DIR/tenmb.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" == *"tenmb.js"* ]]
}

@test "Size: Accept files under 10MB limit" {
    head -c $((100 * 1024)) < /dev/zero | tr '\0' 'x' > "$TEST_DIR/small.js"

    run bash -c "echo '$TEST_DIR/small.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" == *"small.js"* ]]
}

@test "Size: Multiple files with mixed sizes" {
    printf "small\n" > "$TEST_DIR/small.js"
    head -c $((15 * 1024 * 1024)) < /dev/zero | tr '\0' 'x' > "$TEST_DIR/big.js"

    run bash -c "printf '%s\n' '$TEST_DIR/small.js' '$TEST_DIR/big.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" == *"small.js"* ]]
    [[ "$output" != *"file_path:"*"big.js"* ]]
    [[ "$output" == *"exceeds"* ]]
}

@test "Error: Handle unknown option gracefully" {
    run bash "$SCRIPT_PATH" --invalid 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}
