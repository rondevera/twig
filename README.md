**Twig** lets you track ticket ids, reminders, and other metadata for your Git
branches.

If you use lots of Git branches, you know the struggle. You need to remember the
last few branches you worked on, but `git branch` just lists your branches
alphabetically. It's as useful as listing them in random order. You also need
those branches' ticket ids and ticket statuses, and some reminders to yourself
of what to do next with each branch.

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


Examples
--------

List your branches, and highlight the current branch:

    $ twig

    2012-11-23 18:00:21 (7m ago)  * refactor_all_the_things
    2012-11-24 17:12:09 (4d ago)    development
    2012-11-26 19:45:42 (6d ago)    master

Set info about the current branch, e.g., which ticket it refers to. Just run
`twig <your key> <your value>`:

    $ twig issue 159

                                  issue    branch
                                  -----    ------
    2012-11-23 18:00:21 (7m ago)  159    * refactor_all_the_things
    2012-11-24 17:12:09 (4d ago)  -        development
    2012-11-26 19:45:42 (6d ago)  -        master

Show a single property of the current branch (`twig <your key>`):

    $ twig issue

    159

Set more info about the current branch (`twig <another key> <another value>`):

    $ twig status "Shipped"
    $ twig todo "Test in prod"

                                  issue  status   todo            branch
                                  -----  ------   ----            ------
    2012-11-23 18:35:21 (3d ago)  159    Shipped  Test in prod  * refactor_all_the_things
    2012-11-24 17:12:09 (4d ago)  -      -        -               development
    2012-11-26 19:45:42 (6d ago)  -      -        -               master

Over time, you can track progress on multiple topic branches in parallel, leave
yourself reminders of what to do next for each branch, and anything else you can
come up with:

    $ twig

                                  issue  status       todo            branch
                                  -----  ------       ----            ------
    2012-12-01 18:00:21 (7m ago)  486    In progress  Rebase          optimize_all_the_things
    2012-12-01 16:49:21 (2h ago)  268    In progress  -               whitespace_all_the_things
    2012-11-23 18:35:21 (3d ago)  159    Shipped      Test in prod  * refactor_all_the_things
    2012-11-24 17:12:09 (4d ago)  -      -            -               development
    2012-11-26 19:45:42 (6d ago)  -      -            -               master
