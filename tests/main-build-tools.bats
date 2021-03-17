#!/usr/bin/env bats
# -*- mode: sh -*-

# Tests of typical post-installation toolkit usage for a local
# dev. These tests don't cover Jenkins usage. The scope of these tests
# is the scripts in the toolkit. They don't intend to exercise the
# Docker container or any actual docs tools like Sphinx. You can
# consider them integration tests of the scripts in the toolkit.

function setup {
    # Run each test in an isolated, clean working directory
    TMPDIR=$(mktemp -d)
    # Copy in test fixtures for general use tests. This includes making the
    # working directory look like a minimal docs project and stubbing out the docker command.
    cp tests/fixtures/main-build-tools/* "$TMPDIR"
    PATH="$TMPDIR":$PATH
    # The project has the local version of the toolkit in it
    cp rax-docs "$TMPDIR"
    mkdir -p "$TMPDIR"/.rax-docs
    cp -r ./ "$TMPDIR"/.rax-docs/repo/
    cd "$TMPDIR" || exit 1
}

function teardown {
    # On failure, you almost always need the output to figure out what went wrong
    echo "--- docker-input"
    cat docker-input
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

@test "'setup' builds the docker image for local dev" {
    run ./rax-docs setup
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Setting up local dev environment" ]
    [ "${lines[-1]}" = "setup command completed" ]
    # The old image is removed, if present, and a fresh one is built
    # from the toolkit's Dockerfile
    [ "$(head -1 docker-input)" = "rmi rax-docs:latest" ]
    [ "$(tail -1 docker-input)" = "build .rax-docs/repo/resources -t rax-docs" ]
}
