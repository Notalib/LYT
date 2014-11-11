#!/bin/bash

changed=0
for file in $(git diff-index --name-only --cached HEAD --diff-filter=AMCT); do
  p=$(dirname $file);
  if [ "$p" != "${p#web/app}" ]; then
    changed=1;
    break;
  fi
  if [ "$p" != "${p#web/test}" ]; then
    changed=1;
    break;
  fi
done

if [ $changed -eq 1 ]; then
  cd web && grunt karma:commit
  exit $?
fi

echo 0
