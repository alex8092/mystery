#!/bin/bash

set -e

if [ -z "$1" ]; then
	echo "usage: <mystery>";
	exit 1;
fi

echo "-> Create directory if require";
mkdir -p $HOME/.puzzle/bin
mkdir -p $HOME/.puzzle/config
mkdir -p $HOME/.puzzle/modules
mkdir -p $HOME/.puzzle/autocompletes
mkdir -p $HOME/puzzle/Utils

if [ ! -d $HOME/puzzle/Utils/Tools ]; then
	echo "-> Clone repository";
	yes | git clone git@gitlab.intra.$1.com:Utils/Tools.git $HOME/puzzle/Utils/Tools > /dev/null
else
	echo "-> Update repository";
	(cd $HOME/puzzle/Utils/Tools && git pull origin master 2> /dev/null > /dev/null)
fi

echo "-> Testing for node requirement";
echo "console.log('work');" > $HOME/.puzzle/test.js
result=`node $HOME/.puzzle/test.js`
rm -f $HOME/.puzzle/test.js
if [ "$result" != "work" ]; then
	result=`nodejs $HOME/.puzzle/test.js`
	if [ "$result" != 'work' ]; then
		echo 'node is not installed';
		exit 1;
	else
		echo 'nodejs is installed but recent version of nodejs use an binary named "node", update your nodejs or create a symbolic link';
		exit 1;
	fi
fi

echo "-> Write environment config";
(cd $HOME/puzzle && echo "{ \"working_directory\": \"$PWD\", \"cmd_directory\": \"$PWD/Utils/Tools\", \"binary_directory\": \"$HOME/.puzzle/bin\", \"modules_directory\": \"$HOME/.puzzle/modules\", \"autocompletes_directory\": \"$HOME/.puzzle/autocompletes\", \"config_directory\":\"$HOME/.puzzle/config\", \"progname\": \"puzzle\" }" > $HOME/.puzzle/config/env.js)
(cd $HOME/.puzzle && echo "export PATH=\$HOME/.puzzle/bin:\$PATH\n" > .puzzlerc)

echo "-> Create puzzle binary";
if [ -e $HOME/.puzzle/bin/puzzle ]; then
	rm -f $HOME/.puzzle/bin/puzzle
fi
echo "#!/bin/sh\nnode $HOME/puzzle/Utils/Tools/cmd.js" > $HOME/.puzzle/bin/puzzle

echo "-> Start installation script";
(cd $HOME/puzzle && node Utils/Tools/install.js && cd Utils/Tools && npm install)
export PATH=$HOME/.puzzle/bin:$PATH
