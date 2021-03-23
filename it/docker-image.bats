#!/usr/bin/env bats
# -*- mode: sh -*-

## Integration (slow and destructive) tests of the Docker
## container. Your local image WILL BE OVERWRITTEN when you run these
## tests.
##
## Set the env var NO_DOCKER_BUILD to any value to prevent building a
## new image, but realize that the remaining tests will then run with
## your current image, which may not behave as the tests expect.

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

@test "setup produces a docker image" {
    [ -n "$NO_DOCKER_BUILD" ] && skip "User requested skipping docker image build"
    # Delete any existing image so we see if it really builds one
    docker rmi rax-docs || true
    run ./rax-docs setup
    [ "$status" -eq 0 ]
    docker image inspect rax-docs:latest
}

## If the above test fails, the image won't have been built, and
## everything following will also fail.

@test "the image has python installed" {
    run docker run --rm rax-docs python --version
    # This is the python version matching Jenkins
    [ "$output" = "Python 3.3.6" ]
}

@test "the image has a pip that works with python 2" {
    run docker run --rm rax-docs pip --version
    # As long as we're in Python 2, pip should be less than version 21
    [[ "$output" =~ ^pip\ 20\. ]]
}

@test "the image has sphinx installed" {
    run docker run --rm rax-docs sphinx-build --version
    [ "$output" = "Sphinx (sphinx-build) 1.5.6" ]
}

@test "the image has vale installed" {
    run docker run --rm rax-docs vale --version
    [ "$output" = "vale version 2.4.0" ]
}

@test "the toolkit can use the image to build a simple docs project" {
    mkdir docs
    echo "Hello world" > docs/contents.rst
    touch docs/conf.py
    run ./rax-docs html
    [ "$status" -eq 0 ]
    [ -f docs/_build/html/contents.html ]
    [[ "$(cat docs/_build/html/contents.html)" =~ Hello\ world ]]
}

@test "the toolkit can use the image to test a simple docs project" {
    mkdir docs
    echo "Hello world. The pencil will be returned upon completion." > docs/contents.rst
    echo "from sphinxcontrib import spelling" > docs/conf.py
    echo "extensions = ['sphinxcontrib.spelling']" >> docs/conf.py
    run ./rax-docs test
    [ "$status" -eq 0 ]
    PHRASES=(
	# The html pages get built
	'HTML finished. The pages are in'
	# Vale checks style
	'Vale Finished. Output is in'
	# It should've found an error
	"'be returned' looks like"
	# doc8 check style
	'Detailed error counts:'
	# spelling runs
	'Spell check finished. The spellcheck output is in'
    )
    for PHRASE in "${PHRASES[@]}"; do
	echo "Check phrase: $PHRASE"
	[[ "$output" =~ $PHRASE ]]
    done

    # Make a failure
    echo "Make splling check fail!" >> docs/contents.rst
    run ./rax-docs test
    [ "$status" -eq 1 ]
    [[ "$output" =~ Found\ 1\ misspelled\ words ]]
}
