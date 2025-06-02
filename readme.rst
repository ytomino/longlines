Longlines checker
=================

Detects lines longer than the specified columns.

Prerequisites
-------------

gcc 7
 http://gcc.gnu.org/
drake
 https://github.com/ytomino/drake

Install
-------

.. role:: path(emphasis)

The prerequisite is that drkae is already installed in :path:`$DRAKE_RTSDIR`.

Install longlines command to :path:`$PREFIX/bin`: ::

 $ make install RTSDIR=$DRAKE_RTSDIR PREFIX=$HOME/opt/longlines

Or install to :path:`$BINDIR`: ::

 $ make install-bin RTSDIR=$DRAKE_RTSDIR BINDIR=$HOME/bin

Usage
-----

Check the lines in one file: ::

 $ longlines SOURCEFILE.txt

Check the lines added in one patch of unified diff format: ::

 $ longlines -d PATCHFILE.diff

Check the lines to be added before git commit: ::

 $ git diff --cached | longlines -d -p1

An example of :path:`.git/hooks/pre-commit`: ::

 #!/bin/sh
 
 failed=
 trap 'failed=y' USR1
 if ! { git diff --cached 2> /dev/null || kill -s USR1 "$$"; } \
         | longlines -d -p1 -- exit1 >&2
 then
         exit 1
 fi
 if [ -n "$failed" ]; then
         printf "%s: not a git repository\n" "$0"
         exit 1
 fi
