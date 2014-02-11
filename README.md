Twig: Your personal Git branch assistant.
=========================================

[![Gem Version](https://badge.fury.io/rb/twig.png)](http://badge.fury.io/rb/twig)
[![Build Status](https://travis-ci.org/rondevera/twig.png?branch=development)](https://travis-ci.org/rondevera/twig)

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
    2013-01-26 18:00:21 (7m ago)  486    In progress  Rebase          optimize-all-the-things
    2013-01-26 16:49:21 (2h ago)  268    In progress  -               whitespace-all-the-things
    2013-01-23 18:35:21 (3d ago)  159    Shipped      Test in prod  * refactor-all-the-things
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
* `twig init-completion`:                Set up tab completion for `-b` and `--branch`
* `twig init-completion --force`:        Update to the latest tab completion script
* `twig --help`:                         More info


Display options
---------------

* `twig --header-style <format>`:       Change the header style, e.g., "red", "green bold"
* `twig --branch-width <number>`:       Set the character width for the `branch` column
* `twig --<property>-width <number>`:   Set the character width for a specific property column
* `twig --reverse`:                     List oldest branches first


Filtering options
-----------------

Twig lists all of your branches by default (newest first), but you can filter
them by age, name, and custom properties:

* `twig --max-days-old <age>`:
  Only list branches below a given age
* `twig --only-branch <pattern>`:
  Only list branches whose name matches a given pattern
* `twig --except-branch <pattern>`:
  Don't list branches whose name matches a given pattern
* `twig --only-<property> <pattern>`:
  Only list branches with a given property that matches a given pattern
* `twig --except-<property> <pattern>`:
  Don't list branches with a given property that matches a given pattern
* `twig --all`:
  List all branches regardless of other filtering options

You can put your most frequently used options into `~/.twigconfig`, and they'll
be automatically included when you run `twig`. Example:

    # ~/.twigconfig:
    except-branch: staging
    header-style:  green bold
    max-days-old:  30
    reverse:       true


Examples
--------

List your branches, and highlight the current branch:

    $ twig

    2013-01-26 18:07:21 (7m ago)  * refactor-all-the-things
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

    $ twig diff-branch branch2 -b branch3
    Saved property "diff-branch" as "branch2" for branch "branch3".

    $ twig diff-branch branch1 -b branch2
    Saved property "diff-branch" as "branch1" for branch "branch2".

    $ twig

                                  diff-branch    branch
                                  -----------    ------
    2013-01-26 18:00:25 (7m ago)  branch2        branch3
    2013-01-26 16:49:47 (2h ago)  branch1        branch2
    2013-01-23 18:35:12 (3d ago)  -              branch1
    2013-01-22 17:12:23 (4d ago)  -            * master

You can set just about any custom property you need to remember for each branch.


Subcommands
===========

A Twig subcommand is a little script that makes use of a branch's Twig
properties. You can [write your own](#writing-a-subcommand), but here are some
subcommands that Twig comes with.


twig checkout-child
-------------------

Twig uses each branch's `diff-branch` property to remember its parent branch so
you don't have to. If you need to check out one of the child branches for your
current branch, you can use `twig checkout-child`:

    $ git checkout feature-branch

    # Look for any branch whose `diff-branch` property is `feature-branch`, and
    # checkout that branch:
    $ twig checkout-child

    # If the current branch has multiple child, Twig asks what to do:
    Checkout which child branch?
     1. child-branch-1
     2. child-branch-2
     3. child-branch-3
    > 3
    Switched to branch 'child-branch-3'

More advanced usage:

    # Switch to a child branch of any other branch:
    $ twig checkout-child -b other-feature-branch
    Switched to branch 'other-child-branch'

You can use this with `twig checkout-parent` and `twig create-branch` to
traverse your tree of branches.


twig checkout-parent
--------------------

If your branch has a `diff-branch` property, you can use `twig checkout-parent`
to quickly switch to that branch:

    $ git checkout branch2

    # Remember your branch's diff branch:
    $ twig diff-branch branch1
    Saved property "diff-branch" as "branch1" for branch "branch2".

    # Later, switch from branch2 (the current branch) to its parent branch:
    $ twig checkout-parent
    Switched to branch 'branch1'

More advanced usage:

    # Switch to the parent branch of any other branch:
    $ twig checkout-parent -b other-branch-2
    Switched to branch 'other-branch-1'

You can use this with `twig checkout-child` and `twig create-branch` to traverse
your tree of branches.


twig create-branch
------------------

When creating a branch, you can use `twig create-branch` to create a child
branch and set its `diff-branch` property automatically:

    $ git checkout master
    $ twig create-branch my-branch
    Branch my-branch set up to track local branch master.
    Switched to a new branch 'my-branch'
    Saved property "diff-branch" as "master" for branch "my-branch".

    # Confirm that the new branch's `diff-branch` is its parent:
    $ twig diff-branch
    master

    # Check out the new branch's parent:
    $ twig checkout-parent
    Switched to branch 'master'

You can use this with `twig checkout-child` and `twig checkout-parent` to
traverse your tree of branches.


twig diff
---------

If you have a stack of branches with different parent branches, it gets tricky
to remember which branch to diff against. `twig diff` makes it easy:

    $ git checkout branch2

    # Remember your branch's diff branch:
    $ twig diff-branch branch1
    Saved property "diff-branch" as "branch1" for branch "branch2".

    # Generate a diff between branch1 (the current branch) and branch2:
    $ twig diff

More advanced usage:

    # Generate a diff between any given branch and its `diff-branch`:
    $ twig diff my-other-branch

    # Pass options through to `git diff`:
    $ twig diff --stat

    # Pipe results to a diff viewer:
    $ twig diff | gitx


twig rebase
-----------

If you have a stack of branches that you need to rebase in the same order every
time, `twig rebase` simplifies the process:

    $ git checkout branch2

    # Remember your branches' diff (parent) branches:
    $ twig diff-branch branch1
    Saved property "diff-branch" as "branch1" for branch "branch2".

    # Rebase branch2 (the current branch) onto branch1:
    $ twig rebase
    Rebase "branch2" onto "development"? (y/n)

More advanced usage:

    # Rebase any given branch onto its `diff-branch`:
    $ twig rebase my-other-branch

    # Pass options through to `git rebase`:
    $ twig rebase -i


twig gh-open
------------

While inside a GitHub repo, run `twig gh-open` to see the repo's GitHub URL, and
open a browser window if possible:

    $ cd myproject

    $ twig gh-open
    GitHub URL: https://github.com/myname/myproject

For GitHub Enterprise or other installations, you can change
`https://github.com` by setting `github-uri-prefix` in `~/.twigrc`.


twig gh-open-issue
------------------

For any branch that has an `issue` property, you can use the `gh-open-issue`
subcommand to view that issue on GitHub:

    # Current branch:
    $ twig gh-open-issue
    GitHub issue URL: https://github.com/myname/myproject/issues/111

    # Any branch:
    $ twig gh-open-issue -b <branch name>
    GitHub issue URL: https://github.com/myname/myproject/issues/222

For GitHub Enterprise or other installations, you can change
`https://github.com` by setting `github-uri-prefix` in `~/.twigrc`.


twig gh-update
--------------

If you're working on an issue for a GitHub repository, the `gh-update`
subcommand syncs issue statuses with GitHub:

    $ git checkout add-feature
    Switched to branch 'add-feature'.

    $ twig issue 222
    Saved property "issue" as "222" for branch "add-feature".

    $ twig

                                  issue  status    branch
                                  -----  ------    ------
    2013-01-26 18:00:25 (7m ago)  222    -       * add-feature
    2013-01-23 18:35:12 (3d ago)  111    -         fix-bug
    2013-01-22 17:12:23 (4d ago)  -      -         master

    $ twig gh-update
    Getting latest states for GitHub issues...
    # Automatically looks up the GitHub issue status for each
    # of your local branches, and saves it locally.

    $ twig

                                  issue  status    branch
                                  -----  ------    ------
    2013-01-26 18:00:25 (7m ago)  222    open    * add-feature
    2013-01-23 18:35:12 (3d ago)  111    closed    fix-bug
    2013-01-22 17:12:23 (4d ago)  -      -         master

Run `twig gh-update` periodically to keep up with GitHub issues locally.

For GitHub Enterprise or other installations, you can change the default
`https://api.github.com` endpoint prefix by setting `github-api-uri-prefix` in
`~/.twigrc`.


Writing a subcommand
--------------------

You can write any Twig subcommand that fits your own Git workflow. To write a
Twig subcommand:

1.  Write a script—any language will do. (If you want to take advantage of
    Twig's option parsing and branch processing, you'll need Ruby. See
    [`bin/twig-checkout-parent`][twig-checkout-parent] for an example.)
2.  Save it with the `twig-` prefix in your `$PATH`,
    e.g., `~/bin/twig-my-subcommand`.
3.  Make it executable: `chmod ugo+x ~/bin/twig-my-subcommand`
4.  Run your subcommand: `twig my-subcommand` (with a *space* after `twig`)

[twig-checkout-parent]: https://github.com/rondevera/twig/blob/master/bin/twig-checkout-parent

Some ideas for subcommands:

* Get each branch's status for any issue tracking system that has an API,
  like [JIRA](http://www.atlassian.com/software/jira/overview),
  [FogBugz](http://www.fogcreek.com/fogbugz/), or
  [Lighthouse](http://lighthouseapp.com/).
* Given an issue tracker id, check out that issue's branch locally. Great for
  following teammates' branches, remembering their issue ids, and knowing when
  they've shipped.
* Generate a formatted list of your branches from the past week. Useful for
  emailing your team about what you're up to.
* Create a gem that contains your team's favorite custom Twig subcommands.

If you write a subcommand that others might appreciate, send a pull request or
add it to the [Twig wiki][wiki]!


More info
=========

* **Requirements:** Tested with Git 1.7.12+ and Ruby 1.8.7, 1.9.2, 1.9.3, 2.0.0,
  and 2.1.0. Probably works with older software, but it's not guaranteed.
* **Contributing:** Found a bug or have a suggestion? [Please open an
  issue][issues] or ping [@ronalddevera on Twitter][twitter]. If you want to
  hack on some features or contribute a subcommand you've written, feel free to
  fork and send a pull request for the **[development branch][dev branch]**.
  (The master branch is for stable builds only.) See the full details in the
  [Contributing][contributing] instructions.
* **History:** [History/changelog for Twig][history]
* **License:** Twig is released under the [MIT License][license].

[issues]:         https://github.com/rondevera/twig/issues
[wiki]:           https://github.com/rondevera/twig/wiki
[twitter]:        https://twitter.com/ronalddevera
[dev branch]:     https://github.com/rondevera/twig/commits/development
[contributing]:   https://github.com/rondevera/twig/blob/master/CONTRIBUTING.md
[history]:        https://github.com/rondevera/twig/blob/master/HISTORY.md
[license]:        https://github.com/rondevera/twig/blob/master/LICENSE.md
