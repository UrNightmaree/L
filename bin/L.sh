#!/bin/bash

# Ussge scripts
usage() {
	echo "
Usage: L <command> [fields...]

Command:
 • lua 					Download and install PUC Lua
 • luajit 			Download and install LuaJIT
 • luarocks 		Download and install Luarocks
 • luvit 				Download and install Luvit
 --------------------------------------------
 • use 					Use Lua environment version, check \"use\" fields for more information
 • remove 			Removes Lua environment (or the version)
 • clean 				Cleans tarball and folder of Lua environment

Fields:
 • lua/luajit/luarocks/luvit
 	 -1 <version> 		The version of the Lua environment to install

 • use
   -1 <lua-env> 		The Lua environment that'll be used
	 -2 [version] 		The version of the Lua environment, leave blank to use latest
	
 • remove
   -1 <lua-env> 		The Lua environment that'll be removed
	 -2 [version] 		The version of the Lua environment, leave blank to remove all

 • clean
   -1 [lua-env] 		The Lua environment folder/tarball that'll be clean, leave blank to clean all"
	exit
}

# Fancy stdoutt

reset=$(echo -e "\e[0m")

tcolor() {
	echo -e "\e[38;5;${1}m"
}

fancy_echo() {
	local dotc;dotc=$(tcolor 249) # Stands for "dot color"
	local prefc;prefc=$(tcolor 12)
	local msgc;msgc=$(tcolor 245)

	echo "${dotc}•${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_err() {
	local xc;xc=$(tcolor 160) # Stands for "x color"
	local prefc;prefc=$(tcolor 1)
	local msgc;msgc=$(tcolor 245)

	echo "${xc}x${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}" >&2
}

fancy_warn() {
	local excc;excc=$(tcolor 3) # Stands for "exclamation color"
	local prefc;prefc=$(tcolor 142)
	local msgc;msgc=$(tcolor 245)

	echo "${excc}!${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_succ() {
	local chc;chc=$(tcolor 10) # Stands for "check color"
	local prefc;prefc=$(tcolor 28)
	local msgc;msgc=$(tcolor 245)

	echo "${chc}√${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_mkdir() {
	mkdir -p $1
	fancy_echo created "created directory \"$1\""
}

fancy_rmdir() {
	rm $1 -fr
	fancy_echo deleted "deleted directory \"$1\""
}







(( "$#" )) || usage

rootd=~/.L

if [[ ! -e ~/.L ]]; then
	dir=(tarball gitdir lua luajit luarocks luvit)

	for d in "${dir[@]}"; do
		fancy_mkdir "${rootd}/${d}"
	done
fi

lua_install() {
	local V=$1

	local upref="https://www.lua.org/ftp"
	local res=$(curl -sI -o /dev/null -w "%{http_code}" $upref/lua-$V.tar.gz)
	
	echo $V | grep -P '^(\d\.\d\.0|\d\.0)$' 1>&/dev/null

	if [[ $? -eq 1 ]]; then
		res=$(curl -sI -o /dev/null -w "%{http_code}" $upref/lua-$V.0.tar.gz)
		V="$V.0"
	fi

	echo $V

	if [[ res -eq 200 ]]; then
		fancy_echo downloading "downloading \"${upref}/lua-$V.tar.gz\""
		curl -R -o $rootd/tarball/lua-$V.tar.gz --progress-bar $upref/lua-$V.tar.gz

		cd $rootd/tarball
		fancy_echo extracting "extracting \"${rootd}/tarball/lua-$V.tar.gz\""
		tar zxf lua-$V.tar.gz

		if false
		then
			mv lua $rootd/lua/$V
		else
			[[ -e $rootd/lua/$V ]] &&
				rm -fr $rootd/lua/$V && mv lua-$V $rootd/lua/$V ||
				mv lua-$V $rootd/lua/$V
		fi

	else
		fancy_err invalid "invalid version \"$V\""
	fi
}

lua_install $1 
