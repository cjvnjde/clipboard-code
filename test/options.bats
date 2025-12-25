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
    printf "console.log('test');\n" > "$TEST_DIR/src/app.js"
    printf "print('test')\n" > "$TEST_DIR/lib/utils.py"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/src"

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"app.js"* ]] || {
        echo "Output does not contain 'app.js'"
        echo "Full output: $output"
        return 1
    }
}

@test "Root: Scan directory with --root flag" {
    mkdir -p "$TEST_DIR/code"
    printf "const x = 1;\n" > "$TEST_DIR/code/main.ts"

    run bash "$SCRIPT_PATH" --root "$TEST_DIR/code"

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"main.ts"* ]] || {
        echo "Output does not contain 'main.ts'"
        echo "Full output: $output"
        return 1
    }
}

@test "Root: -r flag finds nested files" {
    mkdir -p "$TEST_DIR/project/src/components"
    printf "<template></template>\n" > "$TEST_DIR/project/src/components/Button.vue"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/project/src/components"

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"Button.vue"* ]] || {
        echo "Output does not contain 'Button.vue'"
        echo "Full output: $output"
        return 1
    }
}

@test "Root: -r flag respects file filtering" {
    mkdir -p "$TEST_DIR/mixed"
    printf "test\n" > "$TEST_DIR/mixed/code.js"
    printf "binary" > "$TEST_DIR/mixed/binary.bin"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/mixed"

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"code.js"* ]] || {
        echo "Output does not contain 'code.js'"
        echo "Full output: $output"
        return 1
    }
}

@test "Root: -r flag with non-existent directory" {
    run bash "$SCRIPT_PATH" -r "$TEST_DIR/nonexistent" 2>&1

    [ "$status" -ne 0 ] || {
        echo "Expected non-zero status, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"does not exist"* || "$output" == *"Error"* ]]
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
    printf "config=true\n" > "$TEST_DIR/hidden/.env"
    printf "secret=value\n" > "$TEST_DIR/hidden/.secret"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/hidden"

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *".env"* || "$output" == *".secret"* ]] || {
        echo "Output does not contain '.env' or '.secret'"
        echo "Full output: $output"
        return 1
    }
}

@test "Root: Combine -r with directory argument (positional takes precedence)" {
    mkdir -p "$TEST_DIR/other"
    printf "code\n" > "$TEST_DIR/other/file.js"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR" "$TEST_DIR/other"

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"file.js"* ]] || {
        echo "Output does not contain 'file.js'"
        echo "Full output: $output"
        return 1
    }
}

@test "Root: Unknown option shows error" {
    run bash "$SCRIPT_PATH" -x 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "Size: Skip files exceeding 10MB limit" {
    head -c $((11 * 1024 * 1024)) < /dev/zero | tr '\0' 'x' > "$TEST_DIR/large.js"

    run bash -c "echo '$TEST_DIR/large.js' | bash '$SCRIPT_PATH'" 2>&1

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" != *"file_path:"*"large.js"* ]] || {
        echo "File should NOT be in formatted output"
        echo "Full output: $output"
        return 1
    }
    [[ "$output" == *"exceeds"* ]] || {
        echo "Output should contain 'exceeds'"
        echo "Full output: $output"
        return 1
    }
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

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"small.js"* ]] || {
        echo "Output should contain 'small.js'"
        echo "Full output: $output"
        return 1
    }
    [[ "$output" != *"file_path:"*"big.js"* ]] || {
        echo "Big file should NOT be in formatted output"
        echo "Full output: $output"
        return 1
    }
    [[ "$output" == *"exceeds"* ]] || {
        echo "Output should contain 'exceeds'"
        echo "Full output: $output"
        return 1
    }
}

@test "Size: -r flag also respects file size limit" {
    mkdir -p "$TEST_DIR/sized"
    head -c $((12 * 1024 * 1024)) < /dev/zero | tr '\0' 'x' > "$TEST_DIR/sized/large.go"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR/sized" 2>&1

    [ "$status" -eq 0 ] || {
        echo "Expected status 0, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" != *"file_path:"*"large.go"* ]] || {
        echo "File should NOT be in formatted output"
        echo "Full output: $output"
        return 1
    }
    [[ "$output" == *"exceeds"* ]] || {
        echo "Output should contain 'exceeds'"
        echo "Full output: $output"
        return 1
    }
}

@test "Error: Handle unknown option gracefully" {
    run bash "$SCRIPT_PATH" --invalid 2>&1

    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "Error: Non-existent path as argument" {
    run bash "$SCRIPT_PATH" "$TEST_DIR/missing" 2>&1

    [ "$status" -ne 0 ] || {
        echo "Expected non-zero status, got $status"
        echo "Output: $output"
        return 1
    }
    [[ "$output" == *"does not exist"* || "$output" == *"Error"* ]]
}
