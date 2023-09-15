# Contributing to Procore Projects

This document explains the common procedures expected by contributors while submitting code to Procore open source projects.

## Code of Conduct

Please read and abide by the [Code of Conduct](CODE_OF_CONDUCT.md)

## General workflow

Once a GitHub issue is accepted and assigned to you, please follow general workflow in order to submit your contribution:

1. Fork the target repository under your GitHub username.
2. Create a branch in your forked repository for the changes you are about to make.
3. Commit your changes in the branch you created in step 2. All commits need to be signed-off. Check the [legal](#legal) section bellow for more details.
4. Push your commits to your remote fork.
5. Create a Pull Request from your remote fork pointing to the HEAD branch (usually `main` branch) of the target repository.
6. Check the GitHub build and ensure that all checks are green.

## Legal

Procore projects use Developer Certificate of Origin ([DCO](https://GitHub.com/apps/dco/)).

Please sign-off your contributions by doing ONE of the following:

* Use `git commit -s ...` with each commit to add the sign-off or
* Manually add a `Signed-off-by: Your Name <your.email@example.com>` to each commit message.

The email address must match your primary GitHub email. You do NOT need cryptographic (e.g. gpg) signing.

* Use `git commit -s --amend ...` to add a sign-off to the latest commit, if you forgot.

*Note*: Some projects will provide specific configuration to ensure all commits are signed-off. Please check the project's documentation for more details.

## Tests

Make sure your changes are properly covered by automated tests. We aim to build an efficient test suite that is low cost to maintain and bring value to project. Prefer writing unit-tests over heavy end-to-end (e2e) tests. However, sometimes e2e tests are necessary. If you aren't sure, ask one of the maintainers about the requirements for your pull-request.
