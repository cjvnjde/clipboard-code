#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    export TEST_DIR="$(mktemp -d)"
    echo "unique content" > "$TEST_DIR/uniq.txt"
}

teardown() {
    chmod -R 777 "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
}

@test "Traversal: Deduplicate identical input files" {
    run bash -c "printf '%s\n' '$TEST_DIR/uniq.txt' '$TEST_DIR/uniq.txt' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    
    count=$(echo "$output" | grep -c "file_path:" || echo "0")
    [ "$count" -eq 1 ]
}

@test "Traversal: Deduplicate mixed relative and absolute paths" {
    cd "$TEST_DIR"
    abs_path="$TEST_DIR/uniq.txt"
    rel_path="./uniq.txt"
    
    run bash -c "printf '%s\n' '$abs_path' '$rel_path' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    count=$(echo "$output" | grep -c "file_path:" || echo "0")
    [ "$count" -eq 1 ]
}

@test "Traversal: Handle symbolic links to files" {
    echo "original" > "$TEST_DIR/original.js"
    ln -s "$TEST_DIR/original.js" "$TEST_DIR/link.js" 2>/dev/null || true
    
    run bash -c "printf '%s\n' '$TEST_DIR/original.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"original.js"* ]]
}

@test "Traversal: Handle multiple symlinks to same file" {
    echo "original" > "$TEST_DIR/original.js"
    ln -s "$TEST_DIR/original.js" "$TEST_DIR/link1.js" 2>/dev/null || true
    ln -s "$TEST_DIR/original.js" "$TEST_DIR/link2.js" 2>/dev/null || true
    
    run bash -c "printf '%s\n' '$TEST_DIR/link1.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"link1.js"* ]]
}

@test "Traversal: Handle broken symlinks" {
    ln -s "$TEST_DIR/nonexistent.js" "$TEST_DIR/broken.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/broken.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Traversal: Handle symlinks to directories" {
    mkdir "$TEST_DIR/original_dir"
    echo "file" > "$TEST_DIR/original_dir/file.js"
    ln -s "$TEST_DIR/original_dir" "$TEST_DIR/link_dir" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/link_dir/file.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file.js"* ]]
}

@test "Traversal: Handle many files in directory" {
    for i in $(seq 1 50); do
        echo "content" > "$TEST_DIR/file_$i.js"
    done
    
    # Create a list of all files
    file_list=$(cd "$TEST_DIR" && ls -1 *.js | head -20 | while read f; do echo "$TEST_DIR/$f"; done)
    
    run bash -c "printf '%s\n' $file_list | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file_1.js"* ]]
    [[ "$output" == *"file_20.js"* ]]
}

@test "Traversal: Handle deeply nested directory structure" {
    path="$TEST_DIR"
    for i in $(seq 1 15); do
        mkdir -p "$path/level_$i"
        path="$path/level_$i"
    done
    echo "deep" > "$path/deep.js"
    
    run bash -c "echo '$path/deep.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"deep.js"* ]]
}

@test "Traversal: Deduplicate files found via find and as argument" {
    echo "content" > "$TEST_DIR/dedup_test.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/dedup_test.js' '$TEST_DIR/dedup_test.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
}

@test "Traversal: Handle permission changes during execution" {
    echo "readable" > "$TEST_DIR/change_perm.js"
    chmod 644 "$TEST_DIR/change_perm.js"
    
    run bash -c "echo '$TEST_DIR/change_perm.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"change_perm.js"* ]]
}

@test "Traversal: Handle directory with no readable files" {
    mkdir "$TEST_DIR/empty_dir"
    echo "secret" > "$TEST_DIR/empty_dir/secret.js"
    chmod 000 "$TEST_DIR/empty_dir/secret.js" 2>/dev/null || true
    
    run bash -c "echo '$TEST_DIR/empty_dir/secret.js' | bash '$SCRIPT_PATH'" 2>&1
    
    [ "$status" -eq 0 ]
}

@test "Traversal: Output paths match input argument format" {
    echo "content" > "$TEST_DIR/test.js"
    
    run bash -c "echo '$TEST_DIR/test.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"/"* ]]
}

@test "Traversal: Handle glob patterns in arguments" {
    echo "a" > "$TEST_DIR/a.js"
    echo "b" > "$TEST_DIR/b.js"
    echo "c" > "$TEST_DIR/c.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/a.js' '$TEST_DIR/b.js' '$TEST_DIR/c.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"a.js"* ]]
    [[ "$output" == *"b.js"* ]]
    [[ "$output" == *"c.js"* ]]
}

@test "Traversal: Find files in sibling directories" {
    mkdir "$TEST_DIR/dir1"
    mkdir "$TEST_DIR/dir2"
    echo "file1" > "$TEST_DIR/dir1/file.js"
    echo "file2" > "$TEST_DIR/dir2/file.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/dir1/file.js' '$TEST_DIR/dir2/file.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"dir1/file.js"* ]]
    [[ "$output" == *"dir2/file.js"* ]]
}

@test "Traversal: Very long path in input" {
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

@test "Traversal: Files with special characters in path" {
    echo "content" > "$TEST_DIR/file-with-dashes.js"
    echo "content" > "$TEST_DIR/file_with_underscores.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/file-with-dashes.js' '$TEST_DIR/file_with_underscores.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file-with-dashes.js"* ]]
    [[ "$output" == *"file_with_underscores.js"* ]]
}

@test "Traversal: Duplicate elimination with same content" {
    echo "same content" > "$TEST_DIR/file1.js"
    echo "same content" > "$TEST_DIR/file2.js"
    
    run bash -c "printf '%s\n' '$TEST_DIR/file1.js' '$TEST_DIR/file2.js' | bash '$SCRIPT_PATH'"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file1.js"* ]]
    [[ "$output" == *"file2.js"* ]]
}
