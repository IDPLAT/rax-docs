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
    mkdir -p "$TMPDIR"/.rax-docs/config
    echo "TOOLKIT_VERSION=bob" > "$TMPDIR"/.rax-docs/config/bash
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
    # It builds an imaged tagged with the toolkit version from the config file.
    [ "$(cat docker-input)" = "build .rax-docs/repo/resources -t rax-docs:bob" ]
}

@test "'test' runs tests in docker via make" {
    run ./rax-docs test
    [ "$status" -eq 0 ]
    # First, a check to ensure the right version of the dev environment is set up
    [ "$(head -1 docker-input)" = "image inspect rax-docs:bob" ]
    # Then, it runs the command through docker using the makefile
    [[ "$(tail -1 docker-input)" =~ ^run\ .*\ rax-docs:bob\ make\ .*\ test$ ]]
}

@test "'html' builds html in docker via make" {
    run ./rax-docs html
    [ "$status" -eq 0 ]
    # First, a check to ensure the right version of the dev environment is set up
    [ "$(head -1 docker-input)" = "image inspect rax-docs:bob" ]
    # Then, it runs the command through docker using the makefile
    [[ "$(tail -1 docker-input)" =~ ^run\ .*\ rax-docs:bob\ make\ .*\ html$ ]]
}

@test "'htmlvers' builds versioned html in docker via make" {
    run ./rax-docs htmlvers
    [ "$status" -eq 0 ]
    # First, a check to ensure the right version of the dev environment is set up
    [ "$(head -1 docker-input)" = "image inspect rax-docs:bob" ]
    # Then, it runs the command through docker using the makefile
    [[ "$(tail -1 docker-input)" =~ ^run\ .*\ rax-docs:bob\ make\ .*\ htmlvers$ ]]
}

@test "running a command without the dev environment built gives good output" {
    # Simulate a "docker inspect" failure with the docker test fixture
    echo 'echo "$@" > docker-input' > ./docker
    echo '[[ "$@" =~ "image inspect" ]] && exit 1' >> ./docker
    run ./rax-docs html
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" =~ "You need to set up your local environment first" ]]
    # Nothing but the inspect should have run
    [ "$(cat docker-input)" = "image inspect rax-docs:bob" ]
}
