Integration tests
=================

This directory contains integration tests of the project. Integration
tests should:

- Cover the gaps that unit tests can't cover

- Ensure that the individual units, tested separately by unit tests,
  work together

- Be as quick as possible, but be allowed to take time to test things
  that can't be tested in a fast unit test

- Be easy to read, just like a unit test

You can run all integration tests by running

    bats it

in the project root directory.

All integration test files end with the `.bats` extension and live in
this directory. Bats doesn't handle recursive test directories.