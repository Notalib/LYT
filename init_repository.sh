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

TMP_DIR=$PWD

echo "Installing node modules via npm: ";
cd web && npm install || exit $?
cd $TMP_DIR

echo "Installing bower components: ";
cd web && bower install || exit $?
cd $TMP_DIR

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

if [ ! -f web/test/mock/data/test-data-local.js ]; then
    echo "Du need to create web/test/mock/data/test-data-local.js to run tests\nSee the template file here: web/test/mock/data/test-data-local.js-tmpl"
fi
