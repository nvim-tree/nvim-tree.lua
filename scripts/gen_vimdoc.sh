#!/usr/bin/env sh

set -e

if [ ! -d "${NEOVIM_SRC}" ]; then
	echo "\$NEOVIM_SRC not set"
	exit 1
fi

# runtime/doc is hardcoded, copy the help in
mkdir -pv runtime/doc
cp -v "doc/nvim-tree-lua.txt" runtime/doc

# modify gen_vimdoc.lua to use our config
cp -v "${NEOVIM_SRC}/src/gen/gen_vimdoc.lua" scripts/gen_vimdoc.lua
sed -i -E 's/spairs\(config\)/spairs\(require("gen_vimdoc_nvim-tree")\)/g' scripts/gen_vimdoc.lua

# use luacacts etc. from neovim src as well as our specific config
LUA_PATH="${NEOVIM_SRC}/src/?.lua;scripts/gen_vimdoc_config.lua;${LUA_PATH}"

# generate
scripts/gen_vimdoc.lua

# move the new help back out
mv -v "runtime/doc/nvim-tree-lua.txt" doc
rmdir -v runtime/doc
rmdir -v runtime

# clean up
rm -v scripts/gen_vimdoc.lua

