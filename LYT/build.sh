#!/bin/bash

cd "$(dirname "$0")"

# Compile the src
coffee -c -o ./compiled ./src/*.coffee || exit 1

# Run Docco
docco ./src/*.coffee 1> /dev/null || exit 1

# Compile and run the tests
./test/build.sh run
