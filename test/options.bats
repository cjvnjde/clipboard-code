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

@test "Root: Scan directory with -r flag" {
    mkdir -p "$TEST_DIR/src"
    mkdir -p "$TEST_DIR/lib"
    echo "console.log('test')" > "$TEST_DIR/src/app.js"
    echo "print('test')" > "$TEST_DIR/lib/utils.py"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"app.js"* ]]
    [[ "$output" == *"utils.py"* ]]
}

@test "Root: Scan directory with --root flag" {
    mkdir -p "$TEST_DIR/code"
    echo "const x = 1" > "$TEST_DIR/code/main.ts"

    run bash "$SCRIPT_PATH" --root "$TEST_DIR/code"

    [ "$status" -eq 0 ]
    [[ "$output" == *"main.ts"* ]]
}

@test "Root: -r flag finds nested files" {
    mkdir -p "$TEST_DIR/project/src/components"
    echo "<template></template>" > "$TEST_DIR/project/src/components/Button.vue"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/project"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Button.vue"* ]]
}

@test "Root: -r flag respects file filtering" {
    mkdir -p "$TEST_DIR/mixed"
    echo "test" > "$TEST_DIR/mixed/code.js"
    printf "\x00\x01\x02" > "$TEST_DIR/mixed/binary.bin"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/mixed"

    [ "$status" -eq 0 ]
    [[ "$output" == *"code.js"* ]]
    [[ "$output" != *"binary.bin"* ]]
}

@test "Root: -r flag with non-existent directory" {
    run bash "$SCRIPT_PATH" -r "$TEST_DIR/nonexistent" 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
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

@test "Root: -r flag with hidden files only" {
    mkdir -p "$TEST_DIR/hidden"
    echo "config" > "$TEST_DIR/hidden/.env"
    echo "secret" > "$TEST_DIR/hidden/.secret"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/hidden"

    [ "$status" -eq 0 ]
    [[ "$output" == *".env"* ]]
    [[ "$output" == *".secret"* ]]
}

@test "Root: Combine -r with directory argument (positional takes precedence)" {
    mkdir -p "$TEST_DIR/other"
    echo "code" > "$TEST_DIR/other/file.js"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR" "$TEST_DIR/other"

    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Root: Unknown option shows error" {
    run bash "$SCRIPT_PATH" -x 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "Size: Skip files exceeding 10MB limit" {
    dd if=/dev/urandom of="$TEST_DIR/large.js" bs=1M count=11 2>/dev/null

    run bash -c "echo '$TEST_DIR/large.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" != *"large.js"* ]]
    [[ "$output" == *"exceeds"* ]]
}

@test "Size: Accept files at exactly 10MB limit" {
    perl -e 'print "x" x (10 * 1024 * 1024)' > "$TEST_DIR/tenmb.js"

    run bash -c "echo '$TEST_DIR/tenmb.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" == *"tenmb.js"* ]]
}

@test "Size: Accept files under 10MB limit" {
    perl -e 'print "x" x (100 * 1024)' > "$TEST_DIR/small.js"

    run bash -c "echo '$TEST_DIR/small.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" == *"small.js"* ]]
}

@test "Size: Multiple files with mixed sizes" {
    echo "small" > "$TEST_DIR/small.js"
    perl -e 'print "x" x (15 * 1024 * 1024)' > "$TEST_DIR/big.js"

    run bash -c "printf '%s\n' '$TEST_DIR/small.js' '$TEST_DIR/big.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" == *"small.js"* ]]
    [[ "$output" != *"big.js"* ]]
    [[ "$output" == *"exceeds"* ]]
}

@test "Size: -r flag also respects file size limit" {
    mkdir -p "$TEST_DIR/sized"
    perl -e 'print "x" x (12 * 1024 * 1024)' > "$TEST_DIR/sized/large.go"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/sized" 2>&1

    [ "$status" -eq 0 ]
    [[ "$output" != *"large.go"* ]]
    [[ "$output" == *"exceeds"* ]]
}

@test "Error: Handle unknown option gracefully" {
    run bash "$SCRIPT_PATH" --invalid 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "Error: Non-existent path as argument" {
    run bash "$SCRIPT_PATH" "$TEST_DIR/missing" 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
}
