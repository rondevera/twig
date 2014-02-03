How to contribute
=================

Let's make life easier for people who have lots of Git branches.

Found a bug or have a suggestion? [Please open an issue][issues] or ping
[@ronalddevera on Twitter][twitter].

If you want to hack on some code, even better! Here are the basics:

1.  If you plan to work on a large feature or bug fix, first
    [open an issue][issues] first to discuss whether you're on the right track.
    If you're working on something small, go right ahead.
2.  Fork the Twig repo.
3.  Check out the [**`development`** branch][dev branch]; the `master` branch is
    for stable builds only.
4.  Run the tests to make sure that they pass on your machine: `bundle && rake`
5.  Add one or more failing tests for your feature or bug fix.
6.  Write your feature or bug fix to make the test(s) pass.
    * Tests should pass for the Ruby versions listed in
      [.travis.yml][travis.yml], which you can confirm with [rvm][rvm] or
      [rbenv][rbenv].
    * Keep the branch focused on a single topic, rather than covering multiple
      features or bug fixes in a single branch. This makes branches quicker to
      review and merge.
7.  Test the change manually:
    1.  `gem build twig.gemspec`
    2.  `gem install twig-x.y.z.gem` (fill in the current version number)
8.  Push to your fork and submit a pull request.

Thanks for contributing!

[issues]:     https://github.com/rondevera/twig/issues
[twitter]:    https://twitter.com/ronalddevera
[dev branch]: https://github.com/rondevera/twig/commits/development
[rvm]:        https://rvm.io/
[rbenv]:      http://rbenv.org/
[travis.yml]: https://github.com/rondevera/twig/blob/master/.travis.yml
