#!/bin/sh

# Got script from courtesy of http://stackoverflow.com/a/15757989

jshint_path=$PWD/node_modules/.bin/jshint

if [ ! -x $jshint_path ]; then
    echo "\033[41mCOMMIT FAILED:\033[0m You need to install jshint\n"
    exit 1;
fi

files=$(git diff --cached --name-only --diff-filter=ACM | grep ".js$")
if [ "$files" = "" ]; then
    exit 0
fi

pass=true

echo "\nValidating JavaScript:\n"

for file in ${files}; do
    config_file=$PWD/.jshintrc
    tpath=$(dirname $file);
    while [ -d $tpath ]; do
        tfile=$tpath/.jshintrc
        if [ -f $tfile ]; then
            config_file=$tfile
            break;
        fi
        tpath=$(dirname $tpath);
    done

    output=$(jshint --config=${config_file} ${file});
    if [ $? -eq 0 ]; then
        echo "\t\033[32mjshint Passed: ${file}\033[0m"
    else
        echo "\t\033[31mjshint Failed: ${file}\033[0m"
        echo "$output"
        pass=false
    fi
done

echo "\nJavaScript validation complete\n"

if ! $pass; then
    echo "\033[41mCOMMIT FAILED:\033[0m Your commit contains files that should pass jshint but do not. Please fix the JSHint errors and try again.\n"
    exit 1
else
    echo "\033[42mCOMMIT SUCCEEDED\033[0m\n"
fi
