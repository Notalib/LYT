#!/bin/bash

HOOKDIR=$PWD/hooks/pre-commit

for hook in $(find $HOOKDIR -type f | sort -n); do
  $hook || exit $?
done
