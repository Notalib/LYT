#!/bin/bash

cd "$(dirname "$0")"

# Compile the tests
coffee -c -j suite -o ./tests/compiled ./tests/src/*.coffee || exit 1

# Compile the tests and run them in a browser (`open` is MacOS only, I think)
[[ $1 = "run" ]] && [[ `which open` ]] && open ./index.html

exit 0
