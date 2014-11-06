#!/bin/bash

echo "Checking system: "
function checkbin {
    bin=$1;

    which $bin 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "$bin isn't installed on this system";
        exit 1;
    fi
}

checkbin 'node'
checkbin 'npm'
checkbin 'bower'
checkbin 'yo'
checkbin 'grunt'

echo "Installing node modules via npm: ";
npm install || exit $?

echo "Installing bower components: ";
bower install || exit $?

echo "Installing git hook: ";
for hook in hooks/*.sh; do
    name=$(basename $hook);
    name=${name%.sh}
    githook_path=".git/hooks/$name";

    if [ -f $githook_path ]; then
        rm $githook_path
    fi

    ln -vs $PWD/$hook $githook_path || exit $?
done

if [ ! -f test/mock/data/test-data-local.js ]; then
    echo "Du need to create test/mock/data/test-data-local.js to run tests\nSee the template file here: test/mock/data/test-data-local.js-tmpl"
fi
