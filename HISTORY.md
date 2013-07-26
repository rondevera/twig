Twig
====

* ENHANCEMENT: Speed up listing branches by 3–4x.
* ENHANCEMENT: Add `twig diff`, which diffs the current branch against its
  `diff-branch` property, and `twig diff <branch>`, which diffs the given branch
  against its `diff-branch` property.
* ENHANCEMENT: Add `twig rebase`, which rebases the current branch onto the
  branch in its `diff-branch` property, and `twig rebase <branch>`, which
  rebases the given branch onto its `diff-branch`.
* ENHANCEMENT: Add `twig init-completion --force` for overwriting existing
  completion scripts. Useful for upgrading to the latest Twig completion
  scripts.
* ENHANCEMENT: Improve `twig gh-update` error reporting by listing the affected
  API endpoints upon failure.

1.3 (2013-05-22)
----------------
* ENHANCEMENT: Add `--branch-width` and `--<property>-width` options for setting
  custom column widths.
* ENHANCEMENT: Add `--reverse` option for listing least recently updated
  branches first. This can be used in a config file as `reverse: true`.
* ENHANCEMENT: Make `gh-open` and `gh-open-issue` work cross-platform.
  (GH-18. Thanks [ixti](https://github.com/ixti)!)
* FIX: Allow getting, setting, and unsetting properties for branches older than
  the `max-days-old` option, if given.
* FIX: Abort `twig gh-*` subcommands early if working in a non-Github
  repository.

1.2.1 (2013-05-04)
------------------
* FIX: Add User-Agent string to `twig gh-update` GitHub requests to comply with
  GitHub API v3.

1.2 (2013-03-21)
----------------
* ENHANCEMENT: Add `--only-<property>` and `--except-<property>` options for
  filtering custom properties by value.
* ENHANCEMENT: Simplify setup for writing GitHub-related Twig subcommands.
* FIX: Fix showing `twig --help` outside of a Git repository. (GH-16. Thanks
  [ryangreenberg](https://github.com/ryangreenberg)!)
* FIX: Fix showing `twig --version` outside of a Git repository.
* FIX: Fix the project's homepage URL in `twig --help`. (GH-17. Thanks
  [ryangreenberg](https://github.com/ryangreenberg)!)

1.1 (2013-03-06)
----------------
* ENHANCEMENT: Add branch name tab completion for `-b` and `--branch` options.
  (GH-12)
* ENHANCEMENT: Add `--header-style` option for changing the column headers'
  colors and weights. (GH-11. Thanks [tsujigiri](https://github.com/tsujigiri)!)
* ENHANCEMENT: Add `twig gh-open-issue` for opening a branch's GitHub issue, if
  any, in a browser.
* FIX: Make `branch` a reserved property name, along with `merge`, `rebase`, and
  `remote`.
* FIX: Handle line breaks gracefully in `~/.twigrc` config file.
* FIX: Exit with a non-zero status when trying to get or unset a branch property
  that isn't set, or trying to set a branch property to an invalid value.
* FIX : Don't allow getting/setting/unsetting a branch property whose name is an
  empty string.

1.0.1 (2013-02-13)
------------------
* ENHANCEMENT: Add Travis CI integration for running tests in multiple versions
  of Ruby.
* FIX: Gracefully handle Git config settings where the value is missing.
  (GH-1. Thanks [chrismanderson](https://github.com/chrismanderson)!)
* FIX: Fix failing test in Ruby 1.9.3.
  (GH-7. Thanks [joelmoss](https://github.com/joelmoss)!)
* FIX: Suppress `which` errors.
  (GH-9. Thanks [badboy](https://github.com/badboy)!)
* FIX: Exit with a non-zero status when trying to get a branch property that
  doesn't exist.
* FIX: In list view, render line breaks (in properties) as spaces.

1.0 (2013-02-05)
----------------
* Initial release.
