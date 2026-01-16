#!/usr/bin/env sh

# Wrapper around Nvim help generator gen_vimdoc.lua, run as part of Nvim's make doc target.
#
# Doesn't require Nvim to have been built.
#
# Shims our moudules into gen_vimdoc_config.lua, replacing Nvim's.
#
# There are some hardcoded expectations which we work around as commented.

set -e

if [ ! -d "${NVIM_SRC}" ] && [ -d "src/neovim-stable" ]; then
	export NVIM_SRC="src/neovim-stable"
	echo "${0} assumed NVIM_SRC=${NVIM_SRC}"
fi

if [ ! -d "${NVIM_SRC}" ]; then
	cat << EOM

\$NVIM_SRC not set

Nvim source is required to run src/gen/gen_vimdoc.lua

Please:
  mkdir -p src
  curl -L 'https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz' | tar zx --directory src
  export NVIM_SRC=src/neovim-stable
EOM
exit 1
fi

# unset to ensure no collisions with system installs etc.
unset VIMRUNTIME

# runtime/doc is hardcoded, copy the help in
mkdir -pv runtime/doc
cp -v "doc/nvim-tree-lua.txt" runtime/doc

# modify gen_vimdoc.lua to use our config
cp -v "${NVIM_SRC}/src/gen/gen_vimdoc.lua" gen_vimdoc.lua
sed -i -E 's/spairs\(config\)/spairs\(require("gen_vimdoc_config")\)/g' gen_vimdoc.lua

# use luacacts etc. from neovim src as well as our specific config
export LUA_PATH="${NVIM_SRC}/src/?.lua;scripts/?.lua"

# 1. gen_vimdoc.lua doesn't like to work with a top level lua directory, resulting in modules like 'lua.nvim-tree.api.lua.nvim_tree.api...'
#   -> use a lua subdirectory of runtime
# 2. gen_vimdoc.lua doesn't like dashes in names
#   -> use nvim_tree instead of nvim-tree
# Modules will now be derived from the path under runtime/lua
mkdir -pv runtime/lua
ln -sv ../../lua/nvim-tree runtime/lua/nvim_tree

# generate
./gen_vimdoc.lua

# move the generated help out
mv -v "runtime/doc/nvim-tree-lua.txt" doc

# clean up
rm -v runtime/lua/nvim_tree
rmdir -v runtime/lua
rmdir -v runtime/doc
rmdir -v runtime
rm -v gen_vimdoc.lua

