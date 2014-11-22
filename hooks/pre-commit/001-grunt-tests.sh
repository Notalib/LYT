#!/bin/bash

function okfail {
  if [ $? -ne 0 ]; then
    echo $1
    exit 255;
  fi
}

BASEDIR=$(git rev-parse --show-toplevel 2>/dev/null); okfail "Not in a git repository $?"
WEBDIR="$BASEDIR/web"

[ -d "$WEBDIR" ]; okfail "$WEBDIR isn't a directory";

TESTPREFIX=$BASEDIR/.tmp-hooks/
TMPWEBDIR=$TESTPREFIX/web/

function cleanup {
  [ -d "$TESTPREFIX" ] && rm -rf "$TESTPREFIX"
}

cleanup
trap cleanup EXIT;

[ "$(git diff-index --name-only --cached HEAD --diff-filter=AMCT $WEBDIR | wc -l)" = 0 ] && exit 0;

git checkout-index --prefix=$TESTPREFIX --all; okfail "Couldn't checkout the index"
ln -s $WEBDIR/bower_components $WEBDIR/node_modules $TMPWEBDIR

for template in $(find $WEBDIR/test/ -name "*-tmpl"); do
  file=${template%-tmpl}
  outfile=${file#$WEBDIR}
  [ -f $file ]; okfail "$file doesn't exist"
  cp $file $TMPWEBDIR/$outfile; okfail "Couldn't copy $file";
done

cd $TMPWEBDIR; okfail "Couldn't enter $TMPWEBDIR";
grunt test:commit; okfail "Didn't pass the tests"
