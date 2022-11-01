#!/bin/bash
# shellcheck disable=SC2164 # Disable the "cd ... || exit"

# Ussge scripts
usage() {
	echo "
	Usage: L <command> [fields...]

	Command:
	• lua 							Download and install PUC Lua
	• luajit 					Download and install LuaJIT
	• luarocks 				Download and install Luarocks
	• luvit/luvi/lit 	Download and install Luvit/Luvi/Lit
	--------------------------------------------
	• use 							Use Lua environment version, check \"use\" fields for more information
	• remove 					Remove Lua environment (or the version)
	• clean 						Clean up tarball and folder of Lua environment

	Fields:
	• lua/luajit/luarocks
	1> <version> 		The version of the Lua environment to install

	• luvit/luvi/lit
	1> [version] 		The version of Luvit/Luvi/Lit, leave blank to use in-dev version (branch master)

	• use
	1> <lua-env> 		The Lua environment that'll be used
	2> [version] 		The version of the Lua environment, leave blank to use latest

	• remove
	1> <lua-env> 		The Lua environment that'll be removed
	2> [version] 		The version of the Lua environment, leave blank to remove all

	• clean
	1> [lua-env] 		The Lua environment tarball that'll be clean, leave blank to clean all"
	exit 1
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
	local prefc;prefc=$(tcolor 11)
	local msgc;msgc=$(tcolor 245)

	echo "${excc}!${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_success() {
	local chc;chc=$(tcolor 28) # Stands for "check color"
	local prefc;prefc=$(tcolor 10)
	local msgc;msgc=$(tcolor 245)

	echo "${chc}✓${reset} ${prefc}${1}:${reset} ${msgc}${2}${reset}"
}

fancy_mkdir() {
	mkdir -p "$1"
	fancy_echo created "created directory \"$1\""
}

fancy_rmdir() {
	rm "$1" -fr
	fancy_echo deleted "deleted directory \"$1\""
}


# General
(( "$#" )) || usage

rootd=~/.L

if [[ ! -e ~/.L ]]; then
	fancy_warn "find" "cannot find ~/.L"
	fancy_echo "creating" "creating ~/.L"
	dir=(tarball repo lua luajit luarocks luvit)

	for d in "${dir[@]}"; do
		mkdir "${rootd}/${d}" -p
	done
fi

## Lua ##

# use_lua #
use_lua() {
	local V="$1"

	local filename_lua
	filename_lua=$( which lua 1>&/dev/null &&  echo "lua~" || echo "lua" )
	local filename_luac
	filename_luac=$( which luac 1>&/dev/null && echo "luac~" || echo "luac" )

	local Vdir="$rootd/lua/$V"

	cp -p "$Vdir/bin/lua" "$HOME/.local/bin/$filename_lua"
	cp -p "$Vdir/bin/luac" "$HOME/.local/bin/$filename_luac"
	fancy_success using "using Lua $V 🥳"
}

# lua_build #
lua_build() {
	local V;V=$(echo "$1" | sed -E "s/(\.0){2,}$/.0/g")
	local rawV;rawV=$(echo "$V" | sed -E "s/[.]+//g" )

	# Checking Lua version to build
	if ! echo "$V" | grep -P "^[.0-9]+$" 1>&/dev/null; then
		fancy_err "invalid" "invalid Lua version!"
		exit 1
	fi

	if [[ $rawV -lt 51 ]]; then
		fancy_err error "building below 5.1 is not supported yet!"
		exit 1
	fi

	# Building
	local upref="https://www.lua.org/ftp"

	fancy_echo checking "checking Lua version if is valid"
	local res;res=$(curl -sI -o /dev/null -w "%{http_code}" $upref/lua-"$V".tar.gz)

	if [[ $res -eq 200 ]]; then
		if ! [[ -e "$rootd/tarball/lua-$V.tar.gz" ]]; then
			fancy_echo fetching "fetching \"${upref}/lua-$V.tar.gz\""
			curl -R -o "$rootd/tarball/lua-$V.tar.gz" --progress-bar "$upref/lua-$V.tar.gz"
		else
			fancy_echo tarball "cached tarball found, using current cached tarball..."
		fi

		cd "$rootd"/tarball
		fancy_echo extracting "extracting \"${rootd}/tarball/lua-$V.tar.gz\""
		tar zxf lua-"$V".tar.gz	

		local success_building

		cd lua-"$V"
		fancy_echo building "building Lua version $V"
		if [[ $rawV -lt 540 ]]; then
			make "$(uname -s | tr "[:upper:]" "[:lower:]")" -j "${NPROC:-$(nproc)}"
			success_building=$?
		else
			make all -j "${NPROC:-$(nproc)}"
			success_building=$?
		fi

		(( $success_building )) && {
			fancy_err error "an error has occured while building Lua!"
					exit 1
				}

				make install INSTALL_TOP="$rootd/lua/$V"

				cd $rootd/tarball
				rm -fr lua-"$V"
			else
				fancy_err invalid "invalid version \"$V\""
				exit 1
	fi

	fancy_success building "successfully building Lua $V"
	if ! [[ -e "$HOME"/.local/bin/lua~ && -e "$HOME"/.local/bin/luac~ ]]; then
		use_lua "$V"
	fi
}

## Luvi ##

# luvi_build #
luvi_build() {
	local V=${1:-master}
	V=$(echo "$V" | sed -E "s/^[.0-9]+$/v$V/g")

	local repo="https://github.com/luvit/luvi"

	fancy_echo version "checking Luvi:$V if it is valid"
	local res;res=$(curl -sI -L -o /dev/null -w "%{http_code}" "$repo/archive/$V.tar.gz")

	if [[ $res -ne 200 ]]; then
		fancy_err invalid "invalid Luvi version!"
		exit 1
	fi

	cd $rootd/repo
	if [[ -e "$rootd/repo/luvi-$V" ]]; then
		fancy_echo cloning "cloning Luvi:$V"
		git clone "$repo" "luvi-$V"
	fi
	fancy_echo switching "switching to \"$V\""
	cd "luvi-$V"
	git checkout "$V"

	fancy_echo building "building Luvi:$V"

	make regular -j "${NPROC:-$(nproc)}"
	make -j "${NPROC:-$(nproc)}"

	(( $? )) && {
		fancy_err failed "an error has occured while building Luvi:$V"
#		$DOCLEAN && make clean 1>&/dev/null
		exit 1
	}
}

luvi_build $2
