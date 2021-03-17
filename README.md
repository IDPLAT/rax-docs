[TOC]

A toolkit for building docs based on the [Docs Starter
Kit](https://github.rackspace.com/IX/docs-starter-kit).

Requirements
============

For use:

- [Docker](https://www.docker.com/)
- [Bash](https://www.gnu.org/software/bash/)
- [Git](https://git-scm.com/)

For developing and testing:

- [Bats](https://github.com/bats-core/bats-core/)
- [ShellCheck](https://www.shellcheck.net/)

Why you need it
===============

Documentation projects based on the Docs Starter Kit have a set of
tools built in for building locally and on Jenkins. Why do you need
something else? There are multiple reasons:

- The embedded toolkit needs to be updated from Python 2.

- Setting up a dev environment to use the embedded toolkit is
  non-trivial and poorly documented.

- Improvments to the toolkit can't be distributed to all users.

This toolkit can replace the embedded one and is designed both for
ease of use and to be easy to update and distribute.

Installing
==========

1. Start with a clean working tree. The installation involves adding
and changing some files. In case things go wrong or you change your
mind, you'll use git to undo the changes, so you don't want other
things in the way.

1. Create a file in your project named `rax-docs`, and add the
[content of the rax-docs
script](https://github.com/IDPLAT/rax-docs/blob/master/rax-docs) to
it. (GH Enterprise authentication means I can't make a simple wget
command to get the script.)

1. Install it. Find the [release](https://github.com/IDPLAT/rax-docs/releases) you want and use that as the version to install:

    ```
    chmod +x rax-docs
        ./rax-docs install <version>
    ```

1. Commit the changes it made, including the `rax-docs` script and
config files. Do NOT commit the cloned repository. If it removed
files, those are part of the old toolkit and shouldn't be needed
anymore. If anything looks wrong, you can undo everything with:

    ```
    git reset --hard
    git clean -dff
    ```

Distributing to your team
=========================

If your project already has the toolkit installed, simply  run `./rax-docs get` 
to pull down the full toolkit and use it. This won't make any additional changes 
to the project, as explained below.

Using it
========

After obtaining the toolkit via either `install`ing or `get`ting it,
you have to run `./rax-docs setup` to build your local dev
environment. This builds a local Docker image to act as an isolated
environment.

After the initial setup, the following commands are available.

`rax-docs html`: builds the HTML version of your docs for local review

`rax-docs test`: runs all tests on your docs

`rax-docs htmlvers`: builds multi-versioned HTML docs based on all
existing branches; you can switch versions with a control in the
bottom left of the page in your browser

This toolkit is meant to feel very similar to the original tooling
distributed with the Starter Kit. In general, anything you used to run
with `make` is now run with `./rax-docs` instead.

How it works
============

The goal of this toolkit is to create a centrally upgradeable and
easily distributed set of tools that everyone can use to maintain
docs. The power of the toolkit lies in its ability to push changes out
to all users when something needs to be changed or fixed. This is
counter to the old set of decentralized tools which require users to
make changes to their docs projects when things break or upgrades need
to be made.

The toolkit's design flows out from that goal.

The wrapper script
------------------

First, there's a thin wrapper script, `rax-docs`, which is the primary 
toolkit interface for users. It's how users install the toolkit internals, 
as well as how they run commands to build, test, and publish their 
docs. Build automaters such as Jenkins will also use it this way.

`rax-docs` is the part of the project that is distributed
with all projects. This makes it the most difficult tool element to 
update; therefore, it must be as robust, simple, and, ideally, static as
possible.

To fill this role, the wrapper script is only responsible for
retrieving the main body of the toolkit by cloning the repo from
GitHub. After cloning, it delegates all other commands to scripts in
the local, cloned directory.

The internals
-------------

Anything that's not the wrapper script can be described as
"internals". This is where most of the functionality of the toolkit
lives. The internals can change more freely because they live in the
toolkit repo, instead of every user's project, and can be updated 
using the wrapper.

To decide whether something should go into the internals or the
wrapper script, the answer is always, "Put it in the internals, unless
it's impossible."

Adding to a project
-------------------

The toolkit is installed per project. The wrapper script should be 
downloaded and committed where doc writers can get to it easily, 
like in the root of the project. When you install the rest of the toolkit
using the wrapper, it makes some necessary changes to existing project 
files, like replacing or adding a Jenkinsfile. It keeps everything else inside
a directory called `.rax-docs` for clean separation.

The wrapper script and other required changes made during installation 
need to be committed to the project that's using it. `.rax-docs/repo` contains
the cloned toolkit internals, and `.rax-docs/cache` contains temporary local 
data; these should not be committed, and are therefore in .gitignore.

After you install the toolkit and commit its files to your project,
anyone can clone your project and use the toolkit to build it. They
just have to run `./rax-docs get` to fetch the main toolkit files once
on their local machine. Based on the toolkit configuration stored in
`.rax-docs`, the wrapper knows how to retrieve the right version of
the toolkit to begin using it immediately.

Being stable while changing
---------------------------

During installation, you can select a toolkit version. This allows for version 
pinning; the version you select is always used for your project until a new
version is explicitly installed.

The reason for this version pinning is simple: the toolkit can be updated with 
bugfixes and new features over time. If each change was automatically pulled 
in by every project using it, those projects could potentially break at any time,
which would be frustrating for users. Having users manually update their 
toolkits ensures project stability and the ability to verify upgrades at their own pace.

The toolkit periodically notifies users of new versions to encourage upgrades.
Release versions of the toolkit are indicated by annotated git tags. Annotating
makes it easy to analyze them with commands like `git describe`.

Testing and debugging
=====================

There are bats tests for the main project scripts. When tests fail,
inspecting the output contained in the `$output` var is often
useful. Since the project is bash, you can add a `set +x` to any
function or script to get debug output on the command line.

In addition, the following environment variables are useful during
testing.

`SPEED`: By default, there are some pauses during output for human
readability. Tests shouldn't need to wait for these pauses, so set this to
`true` for faster results.

`NO_DOCKER_BUILD`: The Docker integration tests exercise building the
Docker image for the dev environment. That's a really slow process
that also clobbers your local docs image. Set this variable to any
value to skip tests that build a new image.

See the `tests` and `it` directories for further details on the unit
and integration tests, respectively.
