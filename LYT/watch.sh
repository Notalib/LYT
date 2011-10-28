#!/bin/sh

GROWL=`which growl`

check() {
  chsum1="`stat $1/*.coffee` `stat $2/*.coffee`"
  chsum2=$chsum1
  
  while [[ $chsum1 = $chsum2 ]]; do
    sleep 2
    chsum2="`stat $1/*.coffee` `stat $2/*.coffee`"
  done
  
  compile
}

compile() {
  echo `date "+%H:%M:%S"`
  
  ERROR=$( { coffee -c -o ./compiled ./src/*.coffee; } 2>&1 )
  if [[ $? != 0 ]]; then
    [ $GROWL ] && growl -nosticky "$ERROR" 2>/dev/null
    echo "\tERROR in src:"
    echo "$ERROR"
  else
    echo "\tCompiled src..."
  fi
  
  ERROR=$( { ./test/build.sh; } 2>&1 )
  if [[ $? != 0 ]]; then
    [ $GROWL ] && growl -nosticky "$ERROR" 2>/dev/null
    echo "\tERROR in tests:"
    echo "$ERROR"
  else
    echo "\tCompiled tests..."
  fi
  
  check ./src ./test/tests/src
}

cd "$(dirname "$0")"
compile
