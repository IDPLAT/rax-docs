#!/usr/bin/env bats
# -*- mode: sh -*-

function setup {
    # Tell the script not to pause for human readability
    SPEED=true
    export SPEED
    # The internal script is tied to a version of the wrapper script
    RAX_DOCS_WRAPPER_VERSION=1
    export RAX_DOCS_WRAPPER_VERSION
    # Run each test in an isolated, clean working directory
    TMPDIR=$(mktemp -d)
    # Commiting in an anonymous container will fail without setting
    # the commiter's identity. Commits happen both here and within
    # tests.
    GIT_AUTHOR_NAME=rax-docs-tests
    export GIT_AUTHOR_NAME
    GIT_COMMITTER_NAME=rax-docs-tests
    export GIT_COMMITTER_NAME
    # This script runs from the cloned toolkit directory after the wrapper
    # has cloned it. Set up a fake git repo in the appropriate place so
    # everything looks right to the script.
    mkdir -p "$TMPDIR"/.rax-docs/repo/internal
    mkdir -p "$TMPDIR"/.rax-docs/repo/resources
    cp internal/main "$TMPDIR"/.rax-docs/repo/internal/main
    echo "fake Jenkinsfile for testing" > "$TMPDIR"/.rax-docs/repo/resources/Jenkinsfile
    cd "$TMPDIR"/.rax-docs/repo || exit 1
    git init
    git add .
    git commit -m "fake toolkit repo for testing"
    cd "$TMPDIR" || exit 1
}

function teardown {
    # On failure, you almost always need the output to figure out what went wrong
    echo "--- output"
    echo "$output"
    rm -rf "$TMPDIR"
}

# Useful response strings that answer the prompts of the script. The script asks
# the following questions, depending on the state of things around it:
# 1. (Optional) Really install with dirty working tree?
# 2. (Optional) Really install latest version?
# 3. Github org? (enter to accept discovered)
# 4. Github repo name? (enter to accept discovered)
# 5. Github url? (enter to accept prebuilt)
# 6. Are these settings correct?
# 7. Clean up old toolkit files? (if old files are detected)
#
# Technically, you can answer "y" to every question and get a valid install,
# though the configuration will be weird.
# You can also accept the default for everything except "really install with dirty
# working tree?" by pressing enter and get a valid install.
ALL_YES=$(printf "y\ny\ny\ny\ny\ny\ny\n")
ALL_DEFAULTS=$(printf " \n \n \n \n \n \n \n")

# For easy regex matching and to have a central storage location, here are some
# key phrases that should appear in the script under certain situations.
DIRTY_WARNING="You have uncommitted changes"
LATEST_WARNING="This will use the latest master, which SHOULD be stable"

@test "installing in an empty directory works" {
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [[ "${lines[0]}" =~ Installing\ latest\ toolkit\. ]]
    [ "$status" -eq 0 ]
    # Installing should create some config files based on user choices
    [ -f .rax-docs/config/bash ]
    [ -f .rax-docs/config/groovy ]
}

@test "installing in a clean git directory works" {
    git init
    git commit --allow-empty -m "initial commit"
    run .rax-docs/repo/internal/main internal_install  <<<"$ALL_YES"
    [[ "${lines[0]}" =~ Installing\ latest\ toolkit\. ]]
    [ "$status" -eq 0 ]
    [ -f .rax-docs/config/bash ]
    [ -f .rax-docs/config/groovy ]
}

@test "installing with a dirty working tree works" {
    git init
    git commit --allow-empty -m "initial commit"
    touch foo
    run .rax-docs/repo/internal/main internal_install  <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    [ -f .rax-docs/config/bash ]
    [ -f .rax-docs/config/groovy ]
}

@test "user is warned of dirty working tree and can abort" {
    git init
    git commit --allow-empty -m "initial commit"
    touch foo
    run .rax-docs/repo/internal/main internal_install <<<"$(printf "n\n")"
    [[ "$output" =~ $DIRTY_WARNING ]]
    [ "${lines[-1]}" = "A wise choice, young padawan." ]
    [ "$status" -eq 2 ]
    # If the user bails out this early, we shouldn't appear to have made any changes
    # to their project
    [ ! -d .rax-docs ]
}

@test "user is warned about the risk of installing the latest version and can abort" {
    run .rax-docs/repo/internal/main internal_install <<<"$(printf "n\n")"
    [[ "$output" =~ $LATEST_WARNING ]]
    [ "${lines[-1]}" = "Not installing latest." ]
    [ "$status" -eq 2 ]
    # Again, declining this early means we shouldn't have made any changes
    [ ! -d .rax-docs ]
}

@test "initial optional conditions are bypassed when not relevant" {
    run .rax-docs/repo/internal/main internal_install master <<<"$ALL_YES"
    [ "${lines[0]}" = "Installing toolkit version master." ]
    [ "$status" -eq 0 ]
    ! [[ "$output" =~ $DIRTY_WARNING ]]
    ! [[ "$output" =~ $LATEST_WARNING ]]
}

@test "user-entered settings are stored as config" {
    run .rax-docs/repo/internal/main internal_install master <<<"$(printf "org name\nrepo name\ngit url\ny\n")"
    [ "$status" -eq 0 ]
    EXPECTED="Project settings:
Github org: org name
Repo name : repo name
Clone url : git url"
    [[ "$output" =~ $EXPECTED ]]
    CFG=.rax-docs/config/bash
    grep 'GITHUB_ORG="org name"' $CFG
    grep 'GITHUB_REPO="repo name"' $CFG
    grep 'GIT_CLONE_URL="git url"' $CFG
    grep 'TOOLKIT_VERSION="' $CFG
    CFG=.rax-docs/config/groovy
    grep 'env.GITHUB_ORG="org name"' $CFG
    grep 'env.GITHUB_REPO="repo name"' $CFG
    grep 'env.GIT_CLONE_URL="git url"' $CFG
    grep 'env.TOOLKIT_VERSION="' $CFG
}

@test "installing latest pins to a specific version" {
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    [[ "${lines[6]}" =~ Version:\ (.*) ]]
    REPORTED_VERSION="${BASH_REMATCH[1]}"
    ACTUAL_VERSION=$(git -C .rax-docs/repo rev-parse HEAD)
    SAVED_VERSION=$(grep 'TOOLKIT_VERSION="' .rax-docs/config/bash)
    [ "$REPORTED_VERSION" = "$ACTUAL_VERSION" ]
    [ "$SAVED_VERSION" = "TOOLKIT_VERSION=\"$ACTUAL_VERSION\"" ]
}

@test "installing a branch pins to a specific version" {
    git -C .rax-docs/repo branch bob
    run .rax-docs/repo/internal/main internal_install bob <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Installing toolkit version bob." ]
    [[ "${lines[2]}" =~ Version:\ (.*) ]]
    REPORTED_VERSION="${BASH_REMATCH[1]}"
    ACTUAL_VERSION=$(git -C .rax-docs/repo rev-parse bob)
    SAVED_VERSION=$(grep 'TOOLKIT_VERSION="' .rax-docs/config/bash)
    [ "$REPORTED_VERSION" = "$ACTUAL_VERSION" ]
    [ "$SAVED_VERSION" = "TOOLKIT_VERSION=\"$ACTUAL_VERSION\"" ]
}

@test "installing a tag keeps the tag version" {
    git -C .rax-docs/repo tag fizzby
    run .rax-docs/repo/internal/main internal_install fizzby <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Installing toolkit version fizzby." ]
    [ "${lines[2]}" = "Version: fizzby" ]
    grep 'TOOLKIT_VERSION="fizzby"' .rax-docs/config/bash
}

@test "if a config is already present, project settings are loaded from it" {
    mkdir -p .rax-docs/config
    echo "GITHUB_ORG=bob" >> .rax-docs/config/bash
    echo "GITHUB_REPO=cars" >> .rax-docs/config/bash
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_DEFAULTS"
    CFG=.rax-docs/config/bash
    cat $CFG
    grep 'GITHUB_ORG="bob"' $CFG
    grep 'GITHUB_REPO="cars"' $CFG
    grep 'GIT_CLONE_URL="git@github.rackspace.com:bob/cars.git"' $CFG
    CFG=.rax-docs/config/groovy
    grep 'env.GITHUB_ORG="bob"' $CFG
    grep 'env.GITHUB_REPO="cars"' $CFG
    grep 'env.GIT_CLONE_URL="git@github.rackspace.com:bob/cars.git"' $CFG
}

# The last possible point where a user can stop the installation with no side effects.
@test "user can still abort installation after configuration gathering" {
    run .rax-docs/repo/internal/main internal_install master <<<"$(printf "org name\nrepo name\ngit url\nn\n")"
    [ "$status" -eq 2 ]
    [ "${lines[-4]}" = "Github org: org name" ]
    [ "${lines[-3]}" = "Repo name : repo name" ]
    [ "${lines[-2]}" = "Clone url : git url" ]
    [ "${lines[-1]}" = "Halting installation." ]
    [ ! -d .rax-docs ]
}

@test "after a successful installation, required changes have been made to the project" {
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    [ -f .gitignore ]
    grep '^.rax-docs/repo$' .gitignore
    grep '^.rax-docs/cache$' .gitignore
    [ -f Jenkinsfile ]
    JENKINS_CS=$(sha1sum < Jenkinsfile)
    ACTUAL_JENKINS_CS=$(sha1sum < .rax-docs/repo/resources/Jenkinsfile)
    [ "$JENKINS_CS" = "$ACTUAL_JENKINS_CS" ]
}

@test "doesn't overwrite an existing .gitignore" {
    echo "stuff already ignored" >> .gitignore
    echo "more stuff" >> .gitignore
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    grep '^stuff already ignored$' .gitignore
    grep '^more stuff$' .gitignore
    grep '^.rax-docs/repo$' .gitignore
}

@test "doesn't add duplicate lines to .gitignore" {
    # Given a normal install that adds our gitignore entries
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    [ -f .gitignore ]
    COUNT=$(grep -c '^.rax-docs/' .gitignore)
    [ "$COUNT" = 2 ]
    # When I install a second time
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    # Then the gitignores shouldn't be duplicated
    COUNT=$(grep -c '^.rax-docs/' .gitignore)
    [ "$COUNT" = 2 ]
    # When the gitignore has other entries in it
    echo "more entries" >> .gitignore
    # And I install again
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    # Then the entries still aren't duplicated
    COUNT=$(grep -c '^.rax-docs/' .gitignore)
    [ "$COUNT" = 2 ]
    # And the new entry is still there
    grep '^more entries$' .gitignore
}

@test "installing over an installation succeeds" {
    run .rax-docs/repo/internal/main internal_install master <<<"$(printf "org1\nrepo1\n \ny\n")"
    echo -e "output1:\n$output\n\n"
    [ "$status" -eq 0 ]
    grep 'GITHUB_ORG="org1"' .rax-docs/config/bash
    run .rax-docs/repo/internal/main internal_install master <<<"$(printf "org2\nrepo2\n \ny\n")"
    echo -e "output2:\n$output\n\n"
    [ "$status" -eq 0 ]
    grep 'GITHUB_ORG="org2"' .rax-docs/config/bash
}

@test "installing over the starter kit tools removes them" {
    make_starter_kit_files
    run .rax-docs/repo/internal/main internal_install <<<"$ALL_YES"
    [ "$status" -eq 0 ]
    # The legacy tools should be removed.
    [ ! -f Makefile ]
    [ ! -f requirements.txt ]
    [ ! -d scripts ]
    [ ! -f test.sh ]
    [ ! -f Pipfile ]
    # The Jenksfile should be replaced with ours.
    JENKINS_CS=$(sha1sum < Jenkinsfile)
    ACTUAL_JENKINS_CS=$(sha1sum < .rax-docs/repo/resources/Jenkinsfile)
    [ "$JENKINS_CS" = "$ACTUAL_JENKINS_CS" ]
}

function make_starter_kit_files {
    # To decide if it should remove files, the script looks for a minimal
    # signature consisting of the presence of a few files, along with some
    # key commands. See the script for specifics.
    touch Makefile
    mkdir docs
    touch requirements.txt
    touch docs/Makefile
    echo "source /opt/rh/rh-git29/enable" > Jenkinsfile
    mkdir scripts
    echo "source jenkinspy2/bin/activate" > scripts/build.sh
    # If the signature files and commands are found, many other files are
    # also removed. This list isn't exhaustive. It's just a sample to ensure
    # we're getting to that part of the script.
    touch test.sh
    touch scripts/test.sh
    touch Pipfile
    touch scripts/variables.sh
}
