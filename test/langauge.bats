#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Group 3: Map common extensions to languages (js->javascript, py->python)" {
    echo "log" > "$TEST_DIR/main.js"
    echo "print" > "$TEST_DIR/script.py"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [[ "$output" == *"\`\`\`javascript"* ]]
    [[ "$output" == *"\`\`\`python"* ]]
}

@test "Group 3: Map grouped extensions (h/hpp -> c, yaml/yml -> yaml)" {
    echo "header" > "$TEST_DIR/lib.h"
    echo "config" > "$TEST_DIR/conf.yml"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [[ "$output" == *"\`\`\`c"* ]]
    [[ "$output" == *"\`\`\`yaml"* ]]
}

@test "Group 3: Detect language via Shebang when no extension exists" {
    # Bash shebang
    echo "#!/bin/bash" > "$TEST_DIR/launcher"
    echo "echo hi" >> "$TEST_DIR/launcher"
    
    # Python shebang
    echo "#!/usr/bin/env python3" > "$TEST_DIR/runner"
    echo "pass" >> "$TEST_DIR/runner"

    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    # Check that launcher got labeled as bash
    [[ "$output" == *"\`\`\`bash"* ]]
    # Check that runner got labeled as python
    [[ "$output" == *"\`\`\`python"* ]]
}

@test "Group 3: Fallback to extension name for unknown text files" {
    echo "data" > "$TEST_DIR/file.foobar"
    
    run bash "$SCRIPT_PATH" -r "$TEST_DIR"
    
    [[ "$output" == *"\`\`\`foobar"* ]]
}
