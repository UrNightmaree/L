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
}

# Fancy stdoutt

reset=$(echo -e "\e[0m")

tcolor() {
	echo -e "\e[38;5;${1}m"
}

fancy_echo() {
	local dotc=$(tcolor 249) # Stands for "dot color"
	local prefc=$(tcolor 12)
	local msgc=$(tcolor 245)

	echo "${dotc}•${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_err() {
	local xc=$(tcolor 160) # Stands for "x color"
	local prefc=$(tcolor 1)
	local msgc=$(tcolor 245)

	echo "${xc}x${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}" >&2
}

fancy_warn() {
	local excc=$(tcolor 3) # Stands for "exclamation color"
	local prefc=$(tcolor 142)
	local msgc=$(tcolor 245)

	echo "${excc}!${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_succ() {
	local chc=$(tcolor 10) # Stands for "check color"
	local prefc=$(tcolor 28)
	local msgc=$(tcolor 245)

	echo "${chc}√${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_mkdir() {
	mkdir -p $1
	fancy_echo created "created directory at \"$1\""
}

if [[ $# -le 0 ]]; then
	usage
fi

rootd=~/.L

lua_install() {
	local V=$1

	local upref="https://www.lua.org/ftp"
	local url="${upref}/lua-$V.tar.gz"
	local res=$(curl -I -s -o /dev/null -w "%{http_code}" ${url})

	if [[ res -eq 200 ]]; then
		fancy_echo downloading "downloading \"${upref}/lua-$V.tar.gz\""

		[[ ! -e ~/.L ]] && fancy_mkdir ~/.L/tarball

		curl -R -o ~/.L/tarball/lua-$V.tar.gz --progress-bar ${url}
		cd $rootd/tarball
		tar zxf lua-$V.tar.gz
		cd lua-$V
		make all local PLATFORM=$(uname)
	else
		fancy_err invalid "invalid version \"$V\""
	fi
}

lua_install $1
