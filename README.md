Twig
====

**Twig** lets you track ticket ids, reminders, and other metadata for your Git
branches.

If you use lots of Git branches, you know the struggle. You need to remember the
last few branches you worked on, but `git branch` just lists your branches
alphabetically. It's as useful as listing them in random order. You also need
those branches' ticket ids and ticket statuses, and some reminders of what to do
next with each branch.

Here's what Twig can do for you:

    $ twig

                                  issue  status       todo            branch
                                  -----  ------       ----            ------
    2012-12-01 18:00:21 (7m ago)  486    In progress  Rebase          optimize_all_the_things
    2012-12-01 16:49:21 (2h ago)  268    In progress  -               whitespace_all_the_things
    2012-11-23 18:35:21 (3d ago)  159    Shipped      Test in prod  * refactor_all_the_things
    2012-11-24 17:12:09 (4d ago)  -      -            -               development
    2012-11-26 19:45:42 (6d ago)  -      -            -               master

Twig makes it crazy simple to work with lots of branches. It's flexible enough
to fit your daily Git workflow.


Installation
============

    gem install twig


Usage
=====

Twig lets you get/set custom properties for each branch, and list branches
chronologically with their properties.

* `twig`:                                List all branches with properties
* `twig <property>`:                     Get property for current branch
* `twig <property> <value>`:             Set property for current branch
* `twig --unset <property>`:             Unset property for current branch
* `twig <property> -b <branch>`:         Get property for any branch
* `twig <property> <value> -b <branch>`: Set property for any branch
* `twig --unset <property> -b <branch>`: Unset property for any branch
* `twig --help`:                         More info


Filtering branches
------------------

* `twig --only-branch <pattern>`:
  Only list branches whose name matches a given pattern
* `twig --except-branch <pattern>`:
  Don't list branches whose name matches a given pattern
* `twig --max-days-old <age>`:
  Only list branches below a given age
* `twig --all`:
  List all branches regardless of other filtering options

You can put your most frequently used options into `~/.twigrc`, and they'll be
automatically included when you run `twig`. Example:

    # ~/.twigrc:
    except-branch: staging
    max-days-old:  30


Examples
--------

List your branches, and highlight the current branch:

    $ twig

    2012-11-26 18:07:21 (7m ago)  * refactor_all_the_things
    2012-11-24 17:12:09 (2d ago)    development
    2012-11-23 19:45:42 (3d ago)    master

Set custom info about the current branch, e.g., which ticket it refers to. Just
run `twig <your key> <your value>`:

    $ twig issue 159

                                  issue    branch
                                  -----    ------
    2012-11-26 18:07:21 (7m ago)  159    * refactor_all_the_things
    2012-11-24 17:12:09 (2d ago)  -        development
    2012-11-23 19:45:42 (3d ago)  -        master

Show a single property of the current branch (`twig <your key>`):

    $ twig issue

    159

Set more info about the current branch (`twig <another key> <another value>`):

    $ twig status "Shipped"
    $ twig todo "Test in prod"

                                  issue  status   todo            branch
                                  -----  ------   ----            ------
    2012-11-26 18:07:21 (7m ago)  159    Shipped  Test in prod  * refactor_all_the_things
    2012-11-24 17:12:09 (2d ago)  -      -        -               development
    2012-11-23 19:45:42 (3d ago)  -      -        -               master

Over time, you can track progress on multiple topic branches in parallel, leave
yourself reminders of what to do next for each branch, and anything else you can
come up with:

    $ twig

                                  issue  status       todo            branch
                                  -----  ------       ----            ------
    2012-12-01 18:02:58 (7m ago)  486    In progress  Rebase          optimize_all_the_things
    2012-12-01 16:49:45 (2h ago)  268    In progress  -               whitespace_all_the_things
    2012-11-26 18:07:21 (5d ago)  159    Shipped      Test in prod  * refactor_all_the_things
    2012-11-24 17:12:09 (7d ago)  -      -            -               development
    2012-11-23 19:45:42 (8d ago)  -      -            -               master


Subcommands
===========

If you're working on an issue for a GitHub repository, you can use the
`gh-update` subcommand that comes with Twig. To use it:

1.  Check out the topic branch: `git checkout <branch>`.
2.  Set the GitHub issue number for the branch: `twig issue <issue number>`.
    * To set an issue number for another branch:
      `twig issue <issue number> -b <branch>`.
3.  Run `twig gh-update`. This automatically looks up the GitHub issue status
    for each branch, and saves it locally.

Run `twig` again, and it'll list each branch with its GitHub issue status.
Periodically, you can run `twig gh-update` again to update each branch's status.

You can write any Twig subcommand that fits your own Git workflow. To write a
Twig subcommand:

1.  Write a script. Any language will do.
2.  Save it with the `twig-` prefix in your `$PATH`,
    e.g., `~/bin/twig-my-subcommand`.
3.  Make it executable: `chmod ugo+x ~/bin/twig-my-subcommand`.

Some ideas for subcommands:

* Fetch each branch's status for any bug tracking system, like JIRA or FogBugz.
* Generate a formatted list of your branches from the past week. Useful for
  sending progress updates.


About
=====

- **Requirements:** Tested with Git 1.6.5 and Ruby 1.8.7. Probably works with
  older software, but it's not guaranteed.
- **Contributing:** Found a bug or have a suggestion? [Please open an
  issue][issues] or ping [@ronalddevera on Twitter][twitter]. If you want to
  hack on some features or contribute a subcommand you've written, feel free to
  fork and send a pull request for the **[development branch][dev branch]**.
  (The master branch is for stable builds only.)
- **History:** [History/changelog for Twig][history]
- **License:** Twig is released under the [MIT License][license].

[issues]:     https://github.com/rondevera/twig/issues
[twitter]:    https://twitter.com/ronalddevera
[dev branch]: https://github.com/rondevera/twig/commits/development
[history]:    https://github.com/rondevera/twig/blob/master/HISTORY.md
[license]:    https://github.com/rondevera/twig/blob/master/LICENSE.md
