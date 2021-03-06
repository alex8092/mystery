#!/bin/bash

set -e

if [ -z "$1" ]; then
	echo "usage: <mystery>"
	exit 1
fi

echo "-> Create directory if require"
mkdir -p $HOME/.puzzle/bin
mkdir -p $HOME/.puzzle/config
mkdir -p $HOME/.puzzle/modules
mkdir -p $HOME/.puzzle/autocompletes
mkdir -p $HOME/puzzle/Utils

ssh-keyscan gitlab.intra.$1.com >> $HOME/.ssh/known_hosts
ssh-keyscan gitlab.$1.com >> $HOME/.ssh/known_hosts

if [ ! -d $HOME/puzzle/Utils/Tools ]; then
	echo "-> Clone repository"
	git clone git@gitlab.intra.$1.com:Utils/Tools.git $HOME/puzzle/Utils/Tools >/dev/null
else
	echo "-> Update repository"
	cd $HOME/puzzle/Utils/Tools && git pull origin master >/dev/null 2>&1
fi

echo "-> Testing for node requirement"
echo "console.log('version: ', process.versions.node);" > $HOME/.puzzle/test.js
result=`node $HOME/.puzzle/test.js`
rm -f $HOME/.puzzle/test.js
if ! (echo "$result" | grep 'version:'); then
	if [ "`which node`" == "" ]; then
		echo 'node is not installed'
		exit 1
	elif [ "`which nodejs`" != "" ]; then
		echo 'nodejs is installed but recent version of nodejs use an binary named "node", update your nodejs or create a symbolic link'
		exit 1
	else
		echo 'nodejs is not installed'
		exit 1
	fi
fi

echo "-> Write environment config";
cd $HOME/puzzle && echo "{ \"working_directory\": \"$PWD\", \"cmd_directory\": \"$PWD/Utils/Tools\", \"binary_directory\": \"$HOME/.puzzle/bin\", \"modules_directory\": \"$HOME/.puzzle/modules\", \"autocompletes_directory\": \"$HOME/.puzzle/autocompletes\", \"config_directory\":\"$HOME/.puzzle/config\", \"progname\": \"puzzle\" }" > $HOME/.puzzle/config/env.js
cd $HOME/.puzzle && echo -e "export PATH=\$HOME/.puzzle/bin:\$PATH\nfpath=(\"\${fpath[@]}\" \$HOME/.puzzle/autocompletes)\ncompinit\nunfunction _puzzle\nautoload -U _puzzle\n" > .puzzlerc

echo "-> Create puzzle binary"
if [ -e $HOME/.puzzle/bin/puzzle ]; then
	rm -f $HOME/.puzzle/bin/puzzle
fi
echo -e "#!/bin/sh\nnode $HOME/puzzle/Utils/Tools/cmd.js \$@" > $HOME/.puzzle/bin/puzzle
chmod +x $HOME/.puzzle/bin/puzzle

echo "-> Start installation script"
cd $HOME/puzzle && node Utils/Tools/install.js && cd Utils/Tools && npm install