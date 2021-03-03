#!/usr/bin/env bats
# -*- mode: sh -*-

function setup {
    # Tell the script not to pause for human readability
    export SPEED=true
    # Run each test in an isolated, clean working directory
    TMPDIR=$(mktemp -d)
    # Copy test fixtures into temp dir. These stub out git and the internal script so
    # that installing can be tested without actually cloning anything. Each script
    # writes out what was passed to it in a file named <name>-input. Tests can use
    # these files to verify the inputs.
    cp rax-docs "$TMPDIR"
    cp tests/install-fixtures/* "$TMPDIR"
    PATH="$TMPDIR":$PATH
    cd "$TMPDIR" || exit 1
}

function teardown {
    # Having the inputs and outputs is helpful for fixing failures
    echo "--- git input"
    cat git-input
    echo "--- main input"
    cat main-input
    echo "--- output"
    echo "$output"
    rm -rf "$TMPDIR"
}

@test "running without a command gives some useful output" {
    run ./rax-docs
    [ "${lines[0]}" = "Try 'rax-docs install' to install the toolkit." ]
    [ $status -eq 1 ]
}

@test "running a command not provided by the wrapper prompts to install" {
    run ./rax-docs banana
    [ "${lines[0]}" = "The toolkit hasn't been installed in this project." ]
    [ "${lines[1]}" = "Try running 'rax-docs install <version>'." ]
    [ "${lines[-1]}" = "banana command failed" ]
    [ $status -eq 1 ]
}

@test "running install clones the toolkit" {
    run ./rax-docs install some-version <<<"$(printf "y\ny\ny\ny\ny\ny\ny\n")"
    [ "${lines[-1]}" = "install command completed" ]
    [ $status -eq 0 ]
    [ "$(cat git-input)" = "clone git@github.rackspace.com:dcx/rax-docs.git .rax-docs/repo" ]
    [ "$(cat main-input)" = "internal_install some-version" ]
}

@test "install passes all args to internal script" {
    run ./rax-docs install foo bar baz abc xyz <<<"$(printf "y\ny\ny\ny\ny\ny\ny\n")"
    [ "$(cat main-input)" = "internal_install foo bar baz abc xyz" ]
}

@test "running 'get' in a clean dir is an error" {
    run ./rax-docs get
    [ "${lines[0]}" = "The config file .rax-docs/config/bash is missing." ]
    [ "${lines[1]}" = "Try installing the toolkit with 'rax-docs install <version>'." ]
    [ "${lines[-1]}" = "get command failed" ]
    [ $status -eq 1 ]
}

@test "running 'get' with a target version configured gets the right version" {
    mkdir -p .rax-docs/config
    echo 'TOOLKIT_VERSION="master"' > .rax-docs/config/bash
    run ./rax-docs get
    [ "${lines[-1]}" = "get command completed" ]
    [ $status -eq 0 ]
    run cat git-input
    [ "${lines[0]}" = "clone git@github.rackspace.com:dcx/rax-docs.git .rax-docs/repo" ]
    [ "${lines[1]}" = "-C .rax-docs/repo checkout master" ]
}

@test "running other commands with a target version configured prompts to get the toolkit" {
    mkdir -p .rax-docs/config
    echo 'TOOLKIT_VERSION="master"' > .rax-docs/config/bash
    run ./rax-docs banana
    [ "${lines[0]}" = "The toolkit is configured but not present." ]
    [ "${lines[1]}" = "Try running 'rax-docs get', and then try again." ]
    [ "${lines[-1]}" = "banana command failed" ]
    [ $status -eq 1 ]
}
