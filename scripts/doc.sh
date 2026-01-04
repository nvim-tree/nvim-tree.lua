#!/usr/bin/env sh

set -e

if [ ! -d "${NEOVIM_SRC}" ]; then
	echo "\$NEOVIM_SRC not set"
	exit 1
fi

# runtime/doc is hardcoded, copy it in
mkdir -p runtime/doc
cp "doc/decorator.txt" runtime/doc

# use luacacts etc. from neovim src
LUA_PATH="${NEOVIM_SRC}/src/?.lua"

# generate
scripts/gen_vimdoc.lua

# move the output
mv "runtime/doc/decorator.txt" doc
rmdir runtime/doc
rmdir runtime

