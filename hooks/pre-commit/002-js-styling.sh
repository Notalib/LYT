#!/bin/sh

#######################################################################
# This pre-commit hooks checks for changed or new JavaScript files
# in the commit and checks their style/formating.
#
#######################################################################

has_error=0

WORKING_DIR=$PWD
jsbeautify_path=$(which js-beautify 2>&1);
if [ ! -e "$jsbeautify_path" ]; then
	jsbeautify_path="$WORKING_DIR/node_modules/.bin/js-beautify"
	if [ ! -e "$jsbeautify_path" ]; then
		echo "js-beautify isn't installed and it's required";
		exit 1;
	fi
fi

for file in $(git diff-index --name-only --cached HEAD --diff-filter=AMCT); do
	echo $file | grep "\.js\(on\)\?$" > /dev/null
	if [ $? -eq 0 ]; then
		# Get the staged files hash
		show=$(git diff-index --cached HEAD --diff-filter=AMCT "$file" | cut -d" " -f4);

		# Get the staged file from the index and calculate it's sha1sum to
		current_sha1=$(git show "$show" | sha1sum);
		requried_sha1=$(git show "$show" | $jsbeautify_path -s 2 -P -E -b collapse --wrap-line-length 80 -n /dev/stdin | sha1sum)

		if [ "$current_sha1" != "$requried_sha1" ]; then
			has_error=1;
			echo "$file isn't formatted according to our styling rules"
		fi
	fi
done;

exit $has_error
