#!/usr/bin/env bats
# -*- mode: sh -*-

## A set of tests to enforce a logical project structure and to be
## sure tools like bats and shellcheck are finding all the right
## files.

@test "unit tests are in the 'tests' directory" {
    MYDIR="$BATS_TEST_DIRNAME"
    NAME=$(basename "$MYDIR")
    [ "$NAME" = "tests" ]
}

@test "test files only exist in the test directories" {
    TESTDIR="$BATS_TEST_DIRNAME"
    PROJECTDIR=$(dirname "$TESTDIR")
    ITDIR="$PROJECTDIR"/it
    ALLTESTS=$(find "$PROJECTDIR" -name '*.bats')
    for TEST in $ALLTESTS; do
	echo "Check test: $TEST"
	DIR=$(dirname "$TEST")
	[ "$TESTDIR" = "$DIR" ] || [ "$ITDIR" = "$DIR" ]
    done
}

@test "project root contains the expected files" {
    TESTDIR="$BATS_TEST_DIRNAME"
    PROJECTDIR=$(dirname "$TESTDIR")
    cd "$PROJECTDIR"
    for FILE in *; do
	echo "Check file: $FILE"
	# the wrapper script that people need to download; top
	# level for ease of access
	[ "$FILE" = "rax-docs" ] ||
	    # directory containing internal scripts
	    [ "$FILE" = "internal" ] ||
	    # directory containing additional resources, not script/source files
	    [ "$FILE" = "resources" ] ||
	    # directory containing unit tests
	    [ "$FILE" = "tests" ] ||
	    # directory containing integration tests
	    [ "$FILE" = "it" ] ||
	    # top-level documentation stuff
	    [ "$FILE" = "README.md" ] ||
	    [ "$FILE" = "CONTRIBUTING.md" ]

    done
}

@test "test fixture names match test file names" {
    FIXTUREDIR="$BATS_TEST_DIRNAME/fixtures"
    for F in "$FIXTUREDIR"/*; do
	NAME="$(basename "$F")"
	echo "Fixture: $NAME"
	[ -f "$BATS_TEST_DIRNAME/$NAME.bats" ]
    done
}

@test "Docker and Jenkins Python versions match" {
    FROM_LINE=$(head -1 resources/Dockerfile)
    VERSION=$(echo "$FROM_LINE" | cut -d : -f 2)
    grep "^PYVERSION=$VERSION\$" internal/main
}
