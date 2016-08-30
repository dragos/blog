#!/usr/bin/env bash
set -e # halt script on error

HTML_FOLDER=_site

echo 'Jekyll build...'
jekyll build

cd ${HTML_FOLDER}
pwd

# deploy
git init
git add --all
git commit -m "Deploy to GitHub Pages"
git remote add origin "git@github.com:dragos/dragos.github.com.git"
git push --force origin master

