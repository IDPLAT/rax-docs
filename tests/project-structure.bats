#!/usr/bin/env bats
# -*- mode: sh -*-

## A set of tests to enforce a logical project structure and to be
## sure tools like bats and shellcheck are finding all the right
## files.

@test "tests are in the 'tests' directory" {
    MYDIR="$BATS_TEST_DIRNAME"
    NAME=$(basename "$MYDIR")
    [ "$NAME" = "tests" ]
}

@test "test files only exist in the test directory" {
    TESTDIR="$BATS_TEST_DIRNAME"
    PROJECTDIR=$(dirname "$TESTDIR")
    ALLTESTS=$(find "$PROJECTDIR" -name '*.bats')
    for TEST in $ALLTESTS; do
	echo "Check test: $TEST"
	DIR=$(dirname "$TEST")
	[ "$TESTDIR" = "$DIR" ]
    done
}

@test "project root contains the expected files" {
    # The only files should be the wrapper script and readme. The only
    # dirs should be tests and internal scripts.
    TESTDIR="$BATS_TEST_DIRNAME"
    PROJECTDIR=$(dirname "$TESTDIR")
    cd "$PROJECTDIR"
    for FILE in *; do
	echo "Check file: $FILE"
	[ "$FILE" = "README.md" ] ||
	    [ "$FILE" = "rax-docs" ] ||
	    [ "$FILE" = "internal" ] ||
	    [ "$FILE" = "tests" ]
    done
}
