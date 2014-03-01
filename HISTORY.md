Twig
====

* ENHANCEMENT: Add `--only-property <pattern>` and `--except-property <pattern>`
  for including/excluding property names in list view and JSON view. Useful for
  hiding properties that are frequently too long to show in list view (e.g.,
  `todo`), or for hiding groups of properties that are just issue tracker
  metadata. (GH-25. Thanks [slucero](https://github.com/slucero) for the idea!)
* ENHANCEMENT: Add `twig init` subcommand, the new recommended way to set up
  Twig after installing the gem.
* ENHANCEMENT: Add `twig checkout-parent` subcommand, which checks out the
  current branch's parent branch, if any, based on its `diff-branch` property.
  (GH-34)
* ENHANCEMENT: Add `twig checkout-child` subcommand, which checks out the
  current branch's child branch, if any, based on the child's `diff-branch`
  property. If the current branch has multiple child branches, this subcommand
  lists all of them and prompts for a selection. (GH-35)
* ENHANCEMENT: Add `twig create-branch` subcommand, which creates a branch off
  of the current branch, and sets the child branch's `diff-branch` property
  automatically.
* FIX: Fix `(1y ago)` (previously displayed as `(1 ago)`) in branch list view.
* FIX: Make `property` a reserved property name, along with `branch`, `merge`,
  `rebase`, and `remote`.

1.5 (2013-11-21)
----------------
* ENHANCEMENT: Add `--format=json` option for printing branch data as JSON
  instead of a list. Useful for integrating Twig data into other tools.
* ENHANCEMENT: Add tab completion for all subcommands, built-in (e.g., `twig
  diff`, `twig gh-update`) and custom.
* ENHANCEMENT: Paginate help content where possible.
* ENHANCEMENT: Improve error messages `~/.twigconfig` isn't readable or contains
  invalid lines.
* ENHANCEMENT: Include default option values for branch listing and GitHub
  integration in `twig --help`. (GH-30, GH-31)
* FIX: Fix warnings when listing branches when a branch has UTF-8 characters in
  its name. (GH-20)
* FIX: Fix showing relative time for very old branches (e.g., "2y ago"). (GH-29)

1.4 (2013-08-07)
----------------
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
* FIX: Deprecate `~/.twigrc` in favor of `~/.twigconfig`.

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
* FIX: Don't allow getting/setting/unsetting a branch property whose name is an
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
