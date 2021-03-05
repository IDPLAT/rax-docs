Unit tests
==========

This directory contains unit tests of the project. Unit tests should:

- Be fast, so they can run frequently

- Be easy to read, so other people can understand how a feature is
  supposed to behave

- Catch as many errors as is reasonable, before they make it further
  along the pipeline and get harder to fix

You can run all unit tests by running

    bats tests

in the project root directory.

Test files
----------

A unit test file should focus on one feature or group of related
features that it can easily test with the same setup, teardown and
test fixture(s). All unit tests files end with the `.bats` extension
and live in this directory. Bats doesn't handle recursive test
directories.

Test fixtures
-------------

Test fixtures are in subdirectories of this directory to keep them
organized. Typically, a unit test will use a test fixture by copying
the fixture directory into a temporary working directory for the scope
of the test.
