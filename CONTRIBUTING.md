How to contribute
=================

Let's make life easier for people with lots of Git branches.

Found a bug or have a suggestion? [Please open an issue][issues] or ping
[@ronalddevera on Twitter][twitter].

If you want to hack on some code, even better! Here are the basics:

1.  Fork the Twig repo.
2.  Check out the [**`development`** branch][dev branch]; the `master` branch is
    for stable builds only.
3.  Run the tests to make sure that they pass on your machine: `bundle && rake`
4.  Add one or more failing tests for your feature or bug fix.
5.  Write your feature or bug fix to make the test(s) pass.
6.  Test the change manually:
    1.  `gem build twig.gemspec`
    2.  `gem install twig-x.y.z.gem` (fill in the current version number)
7.  Push to your fork and submit a pull request.

Thanks for contributing!

[issues]:     https://github.com/rondevera/twig/issues
[twitter]:    https://twitter.com/ronalddevera
[dev branch]: https://github.com/rondevera/twig/commits/development
