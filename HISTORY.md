Twig
====

* ENHANCEMENT: Simplify setup for writing GitHub-related Twig subcommands.
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
