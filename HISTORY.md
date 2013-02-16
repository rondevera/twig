Twig
====

* ENHANCEMENT: Add branch name tab completion for `-b` and `--branch` options.
  (GH-12)
* FIX: Make `branch` a reserved property name, along with `merge`, `rebase`, and
  `remote`.

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
