#!/bin/sh

#######################################################################
# This pre-commit hooks checks for changed or new JavaScript files
# in the commit and checks their style/formating.
#
#######################################################################

cd $PWD/web && grunt jscs
exit $?
