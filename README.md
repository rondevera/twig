Twig: Your personal Git branch assistant.
=========================================

It's hard enough trying to remember the names of all of your Git branches. You
also need those branches' issue tracker ids, issue statuses, and reminders of
what to do next with each branch. `git branch` only lists them in alphabetical
order, which just doesn't cut it.

**Twig shows you your most recent branches, and remembers branch details for
you.** It supports subcommands, like automatically fetching statuses from your
issue tracking system. It's flexible enough to fit your everyday Git workflow,
and will save you a ton of time.

Here's how Twig looks in action:

    $ twig

                                  issue  status       todo            branch
                                  -----  ------       ----            ------
    2013-01-26 18:00:21 (7m ago)  486    In progress  Rebase          optimize_all_the_things
    2013-01-26 16:49:21 (2h ago)  268    In progress  -               whitespace_all_the_things
    2013-01-23 18:35:21 (3d ago)  159    Shipped      Test in prod  * refactor_all_the_things
    2013-01-22 17:12:09 (4d ago)  -      -            -               development
    2013-01-20 19:45:42 (6d ago)  -      -            -               master


Installation
============

    gem install twig


Usage
=====

Twig lets you get/set custom properties for each branch, and list branches
chronologically with their properties.

* `twig`:                                List all branches with properties, newest first
* `twig <property>`:                     Get a property for the current branch
* `twig <property> <value>`:             Set a property for the current branch
* `twig --unset <property>`:             Unset a property for the current branch
* `twig <property> -b <branch>`:         Get property for any branch
* `twig <property> <value> -b <branch>`: Set property for any branch
* `twig --unset <property> -b <branch>`: Unset property for any branch
* `twig --help`:                         More info


Filtering branches
------------------

Twig lists all of your branches by default (newest first), but you can filter
them by name and age:

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

    2013-01-26 18:07:21 (7m ago)  * refactor_all_the_things
    2013-01-24 17:12:09 (2d ago)    development
    2013-01-23 19:45:42 (3d ago)    master

Remember a branch's issue tracker id:

    $ git checkout my-branch
    Switched to branch 'my-branch'.

    $ twig issue 123
    Saved property "issue" as "123" for branch "my-branch".
    # Nearly any property name will do, like "bug" or "ticket".

    $ twig issue
    123

    $ open "https://github.com/myname/myproject/issues/`twig issue`"
    # Opens a browser window for this GitHub issue (in OS X).

Keep notes on what you need to do with each branch:

    $ twig todo "Run tests"
    Saved property "todo" as "Run tests" for branch "my-branch".

    $ twig todo "Deploy" -b finished-branch
    Saved property "todo" as "Deploy" for branch "finished-branch".

    $ twig

                                  todo         branch
                                  ----         ------
    2013-01-26 18:00:25 (7m ago)  Run tests  * my-branch
    2013-01-23 18:35:12 (3d ago)  Deploy       finished-branch
    2013-01-22 17:12:23 (4d ago)  -            master

Remember the order in which you were rebasing your stack of branches:

    $ git checkout master
    Switched to branch 'master'.

    $ twig rebase-onto branch2 -b branch3
    Saved property "rebase-onto" as "branch2" for branch "branch3".

    $ twig rebase-onto branch1 -b branch2
    Saved property "rebase-onto" as "branch1" for branch "branch2".

    $ twig

                                  rebase-onto    branch
                                  -----------    ------
    2013-01-26 18:00:25 (7m ago)  branch2        branch3
    2013-01-26 16:49:47 (2h ago)  branch1        branch2
    2013-01-23 18:35:12 (3d ago)  -              branch1
    2013-01-22 17:12:23 (4d ago)  -            * master

You can set just about any custom property you need to remember for each branch.


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
