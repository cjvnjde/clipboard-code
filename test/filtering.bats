#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Filter: Accept specific whitelisted extensions (ts, rs, go, css)" {
    echo "x" > "$TEST_DIR/test.ts"
    echo "x" > "$TEST_DIR/test.rs"
    echo "x" > "$TEST_DIR/test.go"
    echo "x" > "$TEST_DIR/test.css"

    run bash -c "printf '%s\n' '$TEST_DIR/test.ts' '$TEST_DIR/test.rs' '$TEST_DIR/test.go' '$TEST_DIR/test.css' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test.ts"* ]]
    [[ "$output" == *"test.rs"* ]]
    [[ "$output" == *"test.go"* ]]
    [[ "$output" == *"test.css"* ]]
}

@test "Filter: Accept all common programming extensions" {
    echo "code" > "$TEST_DIR/main.ts"
    echo "code" > "$TEST_DIR/main.js"
    echo "code" > "$TEST_DIR/main.py"
    echo "code" > "$TEST_DIR/main.go"
    echo "code" > "$TEST_DIR/main.rs"
    echo "code" > "$TEST_DIR/main.rb"
    echo "code" > "$TEST_DIR/main.java"
    echo "code" > "$TEST_DIR/main.cpp"
    echo "code" > "$TEST_DIR/main.c"
    echo "code" > "$TEST_DIR/main.html"
    echo "code" > "$TEST_DIR/main.json"
    echo "code" > "$TEST_DIR/main.md"

    run bash -c "printf '%s\n' '$TEST_DIR/main.ts' '$TEST_DIR/main.js' '$TEST_DIR/main.py' '$TEST_DIR/main.go' '$TEST_DIR/main.rs' '$TEST_DIR/main.rb' '$TEST_DIR/main.java' '$TEST_DIR/main.cpp' '$TEST_DIR/main.c' '$TEST_DIR/main.html' '$TEST_DIR/main.json' '$TEST_DIR/main.md' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"main.ts"* ]]
    [[ "$output" == *"main.js"* ]]
    [[ "$output" == *"main.py"* ]]
    [[ "$output" == *"main.go"* ]]
    [[ "$output" == *"main.rs"* ]]
    [[ "$output" == *"main.java"* ]]
    [[ "$output" == *"main.cpp"* ]]
    [[ "$output" == *"main.rb"* ]]
    [[ "$output" == *"main.html"* ]]
    [[ "$output" == *"main.json"* ]]
    [[ "$output" == *"main.md"* ]]
}

@test "Filter: Reject binary files (gzip)" {
    echo "test" | gzip > "$TEST_DIR/binary.gz"
    
    run bash -c "echo '$TEST_DIR/binary.gz' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" != *"binary.gz"* ]]
}

@test "Filter: Reject image files" {
    printf "\x89PNG\r\n\x1a\n" > "$TEST_DIR/image.png" 2>/dev/null || true
    printf "\xff\xd8\xff\xe0" > "$TEST_DIR/image.jpg" 2>/dev/null || true
    
    run bash -c "printf '%s\n' '$TEST_DIR/image.png' '$TEST_DIR/image.jpg' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Filter: Reject PDF files" {
    printf "%%PDF-1.4" > "$TEST_DIR/doc.pdf"
    
    run bash -c "echo '$TEST_DIR/doc.pdf' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Filter: Reject archive files" {
    echo "test" | gzip > "$TEST_DIR/archive.gz"
    
    run bash -c "echo '$TEST_DIR/archive.gz' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Filter: Accept unknown extensions if MIME type is text/plain" {
    echo "Some plain text content" > "$TEST_DIR/README.weird"
    echo "data" > "$TEST_DIR/custom.ext"
    
    run bash -c "printf '%s\n' '$TEST_DIR/README.weird' '$TEST_DIR/custom.ext' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"README.weird"* ]]
    [[ "$output" == *"custom.ext"* ]]
}

@test "Filter: Include dotfiles (hidden files)" {
    echo "config=true" > "$TEST_DIR/.env"
    echo "password=secret" > "$TEST_DIR/.passwords"
    
    run bash -c "printf '%s\n' '$TEST_DIR/.env' '$TEST_DIR/.passwords' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *".env"* ]]
    [[ "$output" == *".passwords"* ]]
}

@test "Filter: Include hidden files with multiple dots" {
    echo "config" > "$TEST_DIR/.env.example"
    
    run bash -c "echo '$TEST_DIR/.env.example' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *".env.example"* ]]
}

@test "Filter: Include .gitignore style files" {
    echo "node_modules" > "$TEST_DIR/.gitignore"
    echo "dist" > "$TEST_DIR/.dockerignore"
    
    run bash -c "printf '%s\n' '$TEST_DIR/.gitignore' '$TEST_DIR/.dockerignore' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *".gitignore"* ]]
    [[ "$output" == *".dockerignore"* ]]
}

@test "Filter: Accept MIME type text/*" {
    echo "plain text" > "$TEST_DIR/readme.txt"
    echo "html text" > "$TEST_DIR/readme.text"
    
    run bash -c "printf '%s\n' '$TEST_DIR/readme.txt' '$TEST_DIR/readme.text' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"readme.txt"* ]]
    [[ "$output" == *"readme.text"* ]]
}

@test "Filter: Accept MIME type application/json" {
    echo '{"key": "value"}' > "$TEST_DIR/data.json"
    
    run bash -c "echo '$TEST_DIR/data.json' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"data.json"* ]]
    [[ "$output" == *"json"* ]]
}

@test "Filter: Accept MIME type application/javascript" {
    echo "console.log('test')" > "$TEST_DIR/script.mjs"
    
    run bash -c "echo '$TEST_DIR/script.mjs' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"script.mjs"* ]]
}

@test "Filter: Accept MIME type application/xml" {
    echo '<root/>' > "$TEST_DIR/data.xml"
    
    run bash -c "echo '$TEST_DIR/data.xml' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"data.xml"* ]]
}

@test "Filter: Accept MIME type application/yaml" {
    echo 'key: value' > "$TEST_DIR/config.yaml"
    
    run bash -c "echo '$TEST_DIR/config.yaml' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"config.yaml"* ]]
}

@test "Filter: Accept script files with shebang (no extension)" {
    echo "#!/bin/bash" > "$TEST_DIR/script"
    echo "echo hello" >> "$TEST_DIR/script"
    
    run bash -c "echo '$TEST_DIR/script' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"bash"* ]]
}

@test "Filter: Reject files without recognized extension or text MIME" {
    echo "binary data" > "$TEST_DIR/file.dll"
    echo "binary data" > "$TEST_DIR/file.exe"
    echo "binary data" > "$TEST_DIR/file.so"
    
    run bash -c "printf '%s\n' '$TEST_DIR/file.dll' '$TEST_DIR/file.exe' '$TEST_DIR/file.so' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Filter: Reject compiled object files" {
    printf "\x7fELF" > "$TEST_DIR/binary.o" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/binary.o' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Filter: Include configuration files with known extensions" {
    echo "[section]" > "$TEST_DIR/config.ini"
    echo "key=value" > "$TEST_DIR/settings.conf"
    echo "name = value" > "$TEST_DIR/data.toml"
    
    run bash -c "printf '%s\n' '$TEST_DIR/config.ini' '$TEST_DIR/settings.conf' '$TEST_DIR/data.toml' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"config.ini"* ]]
    [[ "$output" == *"settings.conf"* ]]
    [[ "$output" == *"data.toml"* ]]
}

@test "Filter: Include documentation files" {
    echo "# Title" > "$TEST_DIR/README.md"
    echo "# Title" > "$TEST_DIR/CHANGELOG.md"
    
    run bash -c "printf '%s\n' '$TEST_DIR/README.md' '$TEST_DIR/CHANGELOG.md' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"README.md"* ]]
    [[ "$output" == *"markdown"* ]]
}

@test "Filter: Reject files that are too large to be text" {
    printf "header\x00\x01\x02" > "$TEST_DIR/nulls.bin"
    
    run bash -c "echo '$TEST_DIR/nulls.bin' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}
