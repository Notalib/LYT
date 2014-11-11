#!/bin/sh

#######################################################################
# This pre-commit hooks checks for changed or new JavaScript files
# in the commit and tries to validated them with jshint.
# If any staged file doesn't validate, you don't get to commit the file.
#
# Only three things are required for this script:
# - JSHint must be installed as a commandline tool.
# - the file jshint.conf must exist at the base of the git repository,
#    it contains a JSON with the config parameters for node.js scripts.
# - the file jshint_browser.conf must also exist, this is the same as 
#    the jshint.conf just for the browser. It'll be used on files in
#    the path "public/javascripts", all other files will be validated
#    with the jshint.conf.
#
#######################################################################

has_error=0

# GIT_WORKING_DIR apparently it's $PWD, cache this path
WORKING_DIR=$PWD

jshint_path=$(which jshint 2>&1)
if [ ! -e "$jshint_path" ]; then
	jshint_path="$WORKING_DIR/node_modules/.bin/jshint"
	if [ ! -e $jshint_path ]; then
		echo "JSHint isn't installed and it's required";
		exit 1;
	fi
fi

# Generate a tmp-dir-base-that doesn't overlap with others
TMP_BASEDIR=$WORKING_DIR/.tmp_hooks/$( date | sha1sum | cut -d" " -f1 );
# echo $WORKING_DIR;
# echo $TMP_BASEDIR;
for file in $(git diff-index --name-only --cached HEAD --diff-filter=AMCT | grep "\.js$"); do
	echo $file
	if [ ! -f "$file" ]; then
		continue;
	fi

	echo $file | grep "\.js\$" > /dev/null
	if [ $? -eq 0 ]; then
		# Get the staged files hash
		show=$(git diff-index --cached HEAD --diff-filter=AMCT "$file" | cut -d" " -f4);

		# Make the tmp-path for the file
		TMP_WORKFILE="${TMP_BASEDIR}/${file}";

		# Create the directory for the TMP_WORKFILE
		mkdir -p "$( dirname $TMP_WORKFILE )";

		# Find config-file
		config_file=
		tpath=$(dirname $file);
		tpath=$(readlink -f $tpath);
		lpath=
		while [ -d $tpath ] && [ "$lpath" != "$tpath" ]; do
				tfile=$tpath/.jshintrc
				if [ -f $tfile ]; then
						config_file=$tfile
						break;
				fi

				tfile=$tpath/jshint.conf
				if [ -f $tfile ]; then
						config_file=$tfile
						break;
				fi
				lpath=$tpath
				tpath=$(dirname $tpath);
		done

		# Get the staged file from the index and put it in our working dir, keep the path so it's easier to read.
		git show "$show" > "$TMP_WORKFILE";

		# Go to the tmpbase dir
		cd "$TMP_BASEDIR";

		# Run jshint on the files
		if [ "$config_file" != "" ]; then
			$jshint_path --config "${config_file}" "$file"
		else
			$jshint_path "$file"
		fi

		if [ $? -gt 0 ]; then
			has_error=1;
			echo "$file failed to validate in JSHint using ${config_file}"
		else
			echo "$file validated with JSHint using ${config_file}"
		fi

		# Remove the tmp file and the directory we made for it.
		rm "$TMP_WORKFILE"
		rmdir "$( dirname $TMP_WORKFILE )";

		# Return to the working dir
		cd $WORKING_DIR
	fi
done;

if [ -d "$TMP_BASEDIR" ]; then
	find "$TMP_BASEDIR" -empty -delete
fi

exit $has_error
