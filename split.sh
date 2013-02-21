#!/bin/bash

workdir=$PWD
mkdir -p out

for dir in `cat classlist.txt` # classlist.txt has the paths to the subdirectories
do 
  class=`basename $dir`

  # do a checkout of the entire git repo first
  # and switch to it to work on it
  checkout=out/$class
  if [ -d $checkout ]; then continue; fi
  git clone analysis.git $checkout # analysis.git is the original bare repo you want to split, could be remotely
  cd $workdir/$checkout
  git checkout -b develop origin/develop # might not be necessary in your case
  git remote rm origin # important to avoid pushing back to origin

  # do the actual history rewrite (with aggressive cleanup)
  # you end up with only the stuff & history of $dir
  git tag -l | xargs git tag -d # this deletes all tags
  git filter-branch --tag-name-filter cat --prune-empty --subdirectory-filter $dir -- --all
  git reset --hard
  git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
  git reflog expire --expire=now --all
  git gc --aggressive --prune=now

  cd $workdir
done
