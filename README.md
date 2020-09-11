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

1. Create a file in your project named `rax-docs`, and add the content
from https://github.com/IDPLAT/rax-docs/blob/master/rax-docs
to it. (GH Enterprise authentication means I can't make a simple wget
command to get the script.)

1. Install it. Find the
[release](https://github.com/IDPLAT/rax-docs/releases) you want
and use that as the version to install:

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

Once someone has installed the toolkit in a project, anyone else only
needs to run `./rax-docs get` to pull down the full toolkit and use
it. This won't make any further changes to the project.

Using it
========

After obtaining the toolkit via either `install`ing or `get`ting it,
you have to run `./rax-docs setup` to build your local dev
environment. This builds a Docker image locally to act as an isolated
environment.

After that, this toolkit is meant to feel very similar to the original
one. In general, anything you used to run with `make` is now run with
`./rax-docs` instead. For example,

```
make html
```

is now

```
./rax-docs html
```

and likewise,

```
make test
```

is now

```
./rax-docs test
```

How it works
============

The goal of this toolkit is to make one tool that everyone can use to
maintain docs and that can be centrally upgraded and easily
distributed to all the docs projects when something needs to be
changed or fixed.

Its design flows out from that goal.

The wrapper script
------------------

First, there's a thin wrapper script, which is the primary interface
to the toolkit for users. It's how users install the toolkit, as well
as how they run commands to build, test, and publish their docs. It's
also called from Jenkins to do the same things there.

The wrapper script is the part of the project that gets distributed
into all the projects and will be the part that's the most difficult
to change and the most out of control of the toolkit maintainers;
therefore, it must be robust, simple, and change as little as
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
toolkit repo instead of in every user project.

To decide whether something should go into the internals or the
wrapper script, the answer is always, "Put it in the internals, unless
it's impossible."

Adding to a project
-------------------

The toolkit has to be installed in a project to be any use. The
wrapper script should be downloaded and committed where users can get
to it easily, like in the root of the project. When you install the
rest of the toolkit using the wrapper, it makes some necessary changes
to existing project files, like replacing or adding a Jenkinsfile. It
keeps everything else inside a directory called `.rax-docs` for clean
separation.

The wrapper script, the `.rax-docs` directory, and all the other
changes made during installation need to be committed to the project
that's using it. The directory containing the entire cloned repo is an
exception, so installation adds that directory to the .gitignore of
the project.

Once the toolkit is installed and committed to a project, anyone
cloning the project will have the wrapper script, but be missing the
cloned repository.  Based on the toolkit configuration stored in
`.rax-docs`, the wrapper knows how to retrieve the right version of
the toolkit to begin using immediately.

Being stable while changing
---------------------------

The toolkit can be updated with bugfixes and new features over
time. If each change were automatically pulled in by every project
using it, any project could break at any time, which would be
frustrating for users. To prevent this, you select a toolkit version
when installing it, and the installer stores the version in a
configuration file. That version of the toolkit will always be used
for that project until a new version is explicitly installed.

The toolkit periodically notifies users of new versions to try to
encourage upgrades. Release versions of the toolkit are indicated by
annotated git tags. Annotating makes it easy to analyze them with
commands like `git describe`.

Testing and debugging
=====================

There are bats tests for the script. To make it easier to test, there
are a few variables you can set to alter the script's behavior slightly.

`SPEED`: Set to true to avoid slowing down the output to a more
human-friendly speed. By default, there are some pauses during the
output. Tests shouldn't need to wait for these pauses.

`SOURCE_DIR`: Set to the path of the rax-docs project checked out
locally, and the script will use this directory as the toolkit source
instead of cloning it from GitHub. This speeds up the tests and also
has the benefit of letting us test local changes to the project
without having to commit and push them.
