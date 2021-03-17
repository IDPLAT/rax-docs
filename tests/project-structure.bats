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
	[ "$FILE" = "README.md" ] ||
	    [ "$FILE" = "rax-docs" ] ||
	    [ "$FILE" = "internal" ] ||
	    [ "$FILE" = "resources" ] ||
	    [ "$FILE" = "tests" ] ||
	    [ "$FILE" = "it" ]
    done
}
