Contributing to rax-docs
========================

Thank you for coming here! The more, the merrier. This is intended to
be an inner source kind of project, so your contributions are welcome.

Have a bug to report?
---------------------

Feel free to open [an
issue](https://github.com/IDPLAT/rax-docs/issues) for it. There's no
SLA for issues, but more participation is better for everyone.

Want to make a change?
----------------------

Find an overview of the project in the [top-level
README](https://github.com/IDPLAT/rax-docs/blob/master/README.md#how-it-works)
to get you started.

Once you know what you want to change, just open a PR against the
`master` branch. Keep the following in mind:

- A PR should be small and focused on a single change.

- A PR should be labelled as `feature`, `fix`, or `test`.

- The PR title becomes a changelog entry. Write in the present tense:
  "fixes the thing" instead of "fixed the thing".

- Give a good description of the content of and reason for your change
  in both your commit message and PR description. Future developers,
  including your future self, will thank you.

- PRs are tested automatically when submitted. A successful test run,
  indicated by a commit status on your PR, is required for merging.

- Changes should be accompanied by tests, when appropriate. Much of
  the Jenkins-specific part of the code isn't tested because it's not
  practical to create a Jenkins-like environment in tests. Be really
  careful when making changes there. Try to test it out on Jenkins
  yourself first.
