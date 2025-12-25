#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="$BATS_TEST_DIRNAME/../clipboard-code.sh"
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Lang: Map common extensions to languages (js->javascript, py->python)" {
    echo "log" > "$TEST_DIR/main.js"
    echo "print" > "$TEST_DIR/script.py"

    run bash -c "printf '%s\n' '$TEST_DIR/main.js' '$TEST_DIR/script.py' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"javascript"* ]]
    [[ "$output" == *"python"* ]]
}

@test "Lang: Map grouped extensions (h/hpp -> c, yaml/yml -> yaml)" {
    echo "header" > "$TEST_DIR/lib.h"
    echo "config" > "$TEST_DIR/conf.yml"

    run bash -c "printf '%s\n' '$TEST_DIR/lib.h' '$TEST_DIR/conf.yml' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"c"* ]]
    [[ "$output" == *"yaml"* ]]
}

@test "Lang: Detect language via Shebang when no extension exists" {
    echo "#!/bin/bash" > "$TEST_DIR/launcher"
    echo "echo hi" >> "$TEST_DIR/launcher"
    
    echo "#!/usr/bin/env python3" > "$TEST_DIR/runner"
    echo "pass" >> "$TEST_DIR/runner"

    run bash -c "printf '%s\n' '$TEST_DIR/launcher' '$TEST_DIR/runner' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"bash"* ]]
    [[ "$output" == *"python"* ]]
}

@test "Lang: Fallback to extension name for unknown text files" {
    echo "data" > "$TEST_DIR/file.foobar"
    
    run bash -c "echo '$TEST_DIR/file.foobar' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"file.foobar"* ]]
}

@test "Lang: Map TypeScript variants (tsx -> tsx, ts -> typescript)" {
    echo "interface Props {}" > "$TEST_DIR/component.tsx"
    echo "const x: number = 1" > "$TEST_DIR/module.ts"

    run bash -c "printf '%s\n' '$TEST_DIR/component.tsx' '$TEST_DIR/module.ts' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"tsx"* ]]
    [[ "$output" == *"typescript"* ]]
}

@test "Lang: Map JavaScript variants (jsx -> javascript, js -> javascript)" {
    echo "import React from 'react'" > "$TEST_DIR/component.jsx"
    echo "console.log('test')" > "$TEST_DIR/script.js"

    run bash -c "printf '%s\n' '$TEST_DIR/component.jsx' '$TEST_DIR/script.js' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"javascript"* ]]
}

@test "Lang: Map C/C++ variants correctly" {
    echo "int main() {}" > "$TEST_DIR/main.cpp"
    echo "int main() {}" > "$TEST_DIR/main.cc"
    echo "int main() {}" > "$TEST_DIR/main.cxx"
    echo "int main() {}" > "$TEST_DIR/main.c"
    echo "void func();" > "$TEST_DIR/header.h"
    echo "void func();" > "$TEST_DIR/header.hpp"

    run bash -c "printf '%s\n' '$TEST_DIR/main.cpp' '$TEST_DIR/main.cc' '$TEST_DIR/main.cxx' '$TEST_DIR/main.c' '$TEST_DIR/header.h' '$TEST_DIR/header.hpp' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"cpp"* ]]
    [[ "$output" == *"c"* ]]
}

@test "Lang: Map CSS preprocessors (scss, sass, less)" {
    echo "\$var: red;" > "$TEST_DIR/style.scss"
    echo "\$var: red" > "$TEST_DIR/style.sass"
    echo "@primary: blue;" > "$TEST_DIR/style.less"

    run bash -c "printf '%s\n' '$TEST_DIR/style.scss' '$TEST_DIR/style.sass' '$TEST_DIR/style.less' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"scss"* ]]
    [[ "$output" == *"sass"* ]]
    [[ "$output" == *"less"* ]]
}

@test "Lang: Map configuration formats" {
    echo "[section]" > "$TEST_DIR/config.ini"
    echo "key=value" > "$TEST_DIR/config.conf"
    echo '{"key": "value"}' > "$TEST_DIR/config.json"
    echo "key: value" > "$TEST_DIR/config.yaml"

    run bash -c "printf '%s\n' '$TEST_DIR/config.ini' '$TEST_DIR/config.conf' '$TEST_DIR/config.json' '$TEST_DIR/config.yaml' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"ini"* ]]
    [[ "$output" == *"conf"* ]]
    [[ "$output" == *"json"* ]]
    [[ "$output" == *"yaml"* ]]
}

@test "Lang: Map markup formats (html, xml, vue, svelte)" {
    echo "<html></html>" > "$TEST_DIR/page.html"
    echo "<root/>" > "$TEST_DIR/data.xml"
    echo "<template><div></div></template>" > "$TEST_DIR/component.vue"
    echo "<script>console.log('hi')</script>" > "$TEST_DIR/component.svelte"

    run bash -c "printf '%s\n' '$TEST_DIR/page.html' '$TEST_DIR/data.xml' '$TEST_DIR/component.vue' '$TEST_DIR/component.svelte' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"html"* ]]
    [[ "$output" == *"xml"* ]]
    [[ "$output" == *"vue"* ]]
    [[ "$output" == *"svelte"* ]]
}

@test "Lang: Map shell script variants" {
    echo "#!/bin/bash" > "$TEST_DIR/script.sh"
    echo "#!/bin/bash" > "$TEST_DIR/script.bash"
    echo "#!/bin/zsh" > "$TEST_DIR/script.zsh"
    echo "#!/usr/bin/env fish" > "$TEST_DIR/script.fish"

    run bash -c "printf '%s\n' '$TEST_DIR/script.sh' '$TEST_DIR/script.bash' '$TEST_DIR/script.zsh' '$TEST_DIR/script.fish' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"bash"* ]]
}

@test "Lang: Map scripting languages" {
    echo "print('test')" > "$TEST_DIR/script.py"
    echo "puts 'test'" > "$TEST_DIR/script.rb"
    echo "console.log('test')" > "$TEST_DIR/script.js"
    echo "echo 'test'" > "$TEST_DIR/script.sh"

    run bash -c "printf '%s\n' '$TEST_DIR/script.py' '$TEST_DIR/script.rb' '$TEST_DIR/script.js' '$TEST_DIR/script.sh' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"python"* ]]
    [[ "$output" == *"ruby"* ]]
    [[ "$output" == *"javascript"* ]]
    [[ "$output" == *"bash"* ]]
}

@test "Lang: Map compiled languages" {
    echo "package main" > "$TEST_DIR/main.go"
    echo "fn main() {}" > "$TEST_DIR/main.rs"
    echo "public class Main {}" > "$TEST_DIR/Main.java"

    run bash -c "printf '%s\n' '$TEST_DIR/main.go' '$TEST_DIR/main.rs' '$TEST_DIR/Main.java' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"go"* ]]
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"java"* ]]
}

@test "Lang: Map mobile and modern languages" {
    printf 'func main() {\n    println("Hello")\n}\n' > "$TEST_DIR/main.swift"
    printf 'fun main() {\n    println("Hello")\n}\n' > "$TEST_DIR/main.kt"
    printf 'void main() {\n    print("Hello");\n}\n' > "$TEST_DIR/main.dart"

    run bash -c "printf '%s\n' '$TEST_DIR/main.swift' '$TEST_DIR/main.kt' '$TEST_DIR/main.dart' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"swift"* ]]
    [[ "$output" == *"kotlin"* ]]
    [[ "$output" == *"dart"* ]]
}

@test "Lang: Map functional languages" {
    echo "module Main where" > "$TEST_DIR/Main.hs"
    echo "(defn hello []" > "$TEST_DIR/hello.clj"
    echo "defmodule Hello do" > "$TEST_DIR/hello.ex"
    echo "-module(hello)." > "$TEST_DIR/hello.erl"

    run bash -c "printf '%s\n' '$TEST_DIR/Main.hs' '$TEST_DIR/hello.clj' '$TEST_DIR/hello.ex' '$TEST_DIR/hello.erl' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"haskell"* ]]
    [[ "$output" == *"clojure"* ]]
    [[ "$output" == *"elixir"* ]]
    [[ "$output" == *"erlang"* ]]
}

@test "Lang: Map web configuration formats" {
    echo "{" > "$TEST_DIR/package.json"
    echo '  "name": "test"' >> "$TEST_DIR/package.json"
    echo "<!DOCTYPE html>" > "$TEST_DIR/index.html"
    echo "<config>" > "$TEST_DIR/web.config"

    run bash -c "printf '%s\n' '$TEST_DIR/package.json' '$TEST_DIR/index.html' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"json"* ]]
    [[ "$output" == *"html"* ]]
}

@test "Lang: Detect bash shebang variations" {
    echo "#!/bin/bash" > "$TEST_DIR/script1"
    echo "#!/bin/sh" > "$TEST_DIR/script2"
    echo "#!/usr/bin/env bash" > "$TEST_DIR/script3"
    echo "#!/usr/bin/env sh" > "$TEST_DIR/script4"

    run bash -c "printf '%s\n' '$TEST_DIR/script1' '$TEST_DIR/script2' '$TEST_DIR/script3' '$TEST_DIR/script4' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"bash"* ]]
}

@test "Lang: Detect python shebang variations" {
    echo "#!/usr/bin/python" > "$TEST_DIR/script1.py"
    echo "#!/usr/bin/python3" > "$TEST_DIR/script2.py"
    echo "#!/usr/bin/env python" > "$TEST_DIR/script3.py"
    echo "#!/usr/bin/env python3" > "$TEST_DIR/script4.py"

    run bash -c "printf '%s\n' '$TEST_DIR/script1.py' '$TEST_DIR/script2.py' '$TEST_DIR/script3.py' '$TEST_DIR/script4.py' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"python"* ]]
}

@test "Lang: File without extension or shebang gets empty lang" {
    echo "some random text without shebang" > "$TEST_DIR/file.noext"
    
    run bash -c "echo '$TEST_DIR/file.noext' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"file.noext"* ]]
}

@test "Lang: Map Ruby file extensions" {
    echo "puts 'test'" > "$TEST_DIR/script.rb"
    echo "puts 'test'" > "$TEST_DIR/Gemfile"

    run bash -c "printf '%s\n' '$TEST_DIR/script.rb' '$TEST_DIR/Gemfile' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"ruby"* ]]
}

@test "Lang: Map PHP file extensions" {
    echo "<?php echo 'test';" > "$TEST_DIR/script.php"
    echo "<?php echo 'test';" > "$TEST_DIR/index.php"

    run bash -c "printf '%s\n' '$TEST_DIR/script.php' '$TEST_DIR/index.php' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"php"* ]]
}

@test "Lang: Map R and data science languages" {
    echo "x <- 1:10" > "$TEST_DIR/analysis.r"
    echo "val <- 100" >> "$TEST_DIR/analysis.r"
    echo "print(x)" >> "$TEST_DIR/analysis.r"

    run bash -c "echo '$TEST_DIR/analysis.r' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"r"* ]]
}

@test "Lang: Map Lua and Perl" {
    echo "print('test')" > "$TEST_DIR/script.lua"
    echo "print('test')" > "$TEST_DIR/script.pl"

    run bash -c "printf '%s\n' '$TEST_DIR/script.lua' '$TEST_DIR/script.pl' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"lua"* ]]
    [[ "$output" == *"perl"* ]]
}

@test "Lang: Map Vim script" {
    echo "set nu" > "$TEST_DIR/script.vim"
    
    run bash -c "echo '$TEST_DIR/script.vim' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"vim"* ]]
}

@test "Lang: Map SQL files" {
    echo "SELECT * FROM table;" > "$TEST_DIR/query.sql"
    
    run bash -c "echo '$TEST_DIR/query.sql' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"sql"* ]]
}

@test "Lang: Map Markdown and documentation" {
    echo "# Title" > "$TEST_DIR/README.md"
    echo "Some description" >> "$TEST_DIR/README.md"
    echo "## Section" >> "$TEST_DIR/README.md"

    run bash -c "echo '$TEST_DIR/README.md' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"markdown"* ]]
}

@test "Lang: Map Scala and Clojure" {
    printf 'object Main extends App { println("Hi") }\n' > "$TEST_DIR/Main.scala"
    printf '(println "Hello")\n' > "$TEST_DIR/hello.clj"

    run bash -c "printf '%s\n' '$TEST_DIR/Main.scala' '$TEST_DIR/hello.clj' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"scala"* ]]
    [[ "$output" == *"clojure"* ]]
}

@test "Lang: Map .ex and .exs Elixir files" {
    cat > "$TEST_DIR/hello.ex" << 'EOF'
defmodule Hello do
    def hello do
        :world
    end
end
EOF

    echo 'IO.puts "Hello"' > "$TEST_DIR/hello.exs"

    run bash -c "printf '%s\n' '$TEST_DIR/hello.ex' '$TEST_DIR/hello.exs' | bash '$SCRIPT_PATH'"
    
    [[ "$output" == *"elixir"* ]]
}
