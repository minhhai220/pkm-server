#!/bin/bash


if [ "$1" == release ]; then
	domain="localhost:3000"
else
	svn up
fi
url=git@192.168.1.235:tjgame/LuaGameFramework.git
echo $url

if [ -d "game_scripts/framework" ]; then
	echo "already game_scripts/framework!"
	cd game_scripts/framework
	git pull origin master
	cd ../../
else
	echo "no game_scripts/framework"
	mkdir game_scripts/framework
	cd game_scripts/framework
	git init
	git config http.sslVerify false
	git config core.sparsecheckout true
	git remote add -f origin $url
	echo "/MyLuaGame/src/" >> .git/info/sparse-checkout
	echo "/MyLuaGame/cocos/" >> .git/info/sparse-checkout
	git pull origin master
	cd ../../
fi
