#!/usr/bin/env bats
# -*- mode: sh -*-

# Tests of typical post-installation toolkit usage for a local
# dev. These tests don't cover Jenkins usage.

function setup {
    # Run each test in an isolated, clean working directory
    TMPDIR=$(mktemp -d)
    # The project has the local version of the toolkit in it
    cp rax-docs "$TMPDIR"
    mkdir -p "$TMPDIR"/.rax-docs
    cp -r ./ "$TMPDIR"/.rax-docs/repo/
    cd "$TMPDIR" || exit 1
}

function teardown {
    # On failure, you almost always need the output to figure out what went wrong
    echo "--- output"
    echo "$output"
    rm -rf "$TMPDIR"
}

@test "running without a command shows help" {
    run ./rax-docs
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" =~ Usage:\ rax-docs\ \<command\> ]]
    [[ "$output" =~ DOCS\ BUILDING\ COMMANDS ]]
    [[ "$output" =~ TOOLKIT\ MAINTENANCE\ COMMANDS ]]
}

@test "running an unrecognized command shows help" {
    run ./rax-docs banana
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Unrecognized command: banana" ]
    [[ "${lines[1]}" =~ Usage:\ rax-docs\ \<command\> ]]
    [[ "$output" =~ DOCS\ BUILDING\ COMMANDS ]]
    [[ "$output" =~ TOOLKIT\ MAINTENANCE\ COMMANDS ]]
}

@test "status command works" {
    run ./rax-docs status
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "RAX Docs Toolkit" ]
    [[ "${lines[1]}" =~ ^Version: ]]
    [ "${lines[2]}" = "Install path: .rax-docs" ]
}
