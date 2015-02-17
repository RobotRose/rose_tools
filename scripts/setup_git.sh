#!/bin/bash

# Rose B.V.
# Author: Okke Hendriks
# Date: 05-09-2014
# Script to setup the git enviroment  
# Pipe in the config version file when calling.
# Thus call as follows: ./setup_git.sh < gitconfig_version_file

# IMPORTANT Increase this version variable if you changed the configuration

#git config branch.master.mergeoptions  "--no-ff"
git config --global push.default current
git config --global color.ui true
git config --global credential.helper "cache --timeout=3600"
git config --global help.autocorrect 1
