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

Twig comes with two subcommands, `gh-open` and `gh-update`, which are handy for
use with GitHub repositories.

While inside a Git repo, run `twig gh-open` to see the repo's GitHub URL, and open
a browser window if possible:

    $ cd myproject

    $ twig gh-open
    GitHub URL: https://github.com/myname/myproject
    # Also opens a browser window (OS X only).

If you're working on an issue for a GitHub repository, you can also use the
`gh-update` subcommand:

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
    # Automatically looks up the GitHub issue status for each
    # of your local branches, and saves it locally.

    $ twig

                                  issue  status    branch
                                  -----  ------    ------
    2013-01-26 18:00:25 (7m ago)  222    open    * add-feature
    2013-01-23 18:35:12 (3d ago)  111    closed    fix-bug
    2013-01-22 17:12:23 (4d ago)  -      -         master

Run `twig gh-update` periodically to keep up with GitHub issues locally.

You can write any Twig subcommand that fits your own Git workflow. To write a
Twig subcommand:

1.  Write a script. Any language will do. (If you want to take advantage of
    Twig's option parsing and branch processing, you'll need Ruby. See
    [`bin/twig-gh-update`][twig-gh-update] for an example.)
2.  Save it with the `twig-` prefix in your `$PATH`,
    e.g., `~/bin/twig-my-subcommand`.
3.  Make it executable: `chmod ugo+x ~/bin/twig-my-subcommand`
4.  Run your subcommand: `twig my-subcommand` (with a *space* after `twig`)

[twig-gh-update]: https://github.com/rondevera/twig/blob/master/bin/twig-gh-update

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

If you write a subcommand that others can appreciate, send a pull request or add
it to the [Twig wiki][wiki]!


More info
=========

* **Requirements:** Tested with Git 1.6.5 and Ruby 1.8.7/1.9.2/1.9.3. Probably
  works with older software, but it's not guaranteed.
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
