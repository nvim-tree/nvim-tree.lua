#!/usr/bin/env sh

# Wrapper around Nvim help generator gen_vimdoc.lua, run as part of Nvim's make doc target.
#
# Doesn't require Nvim to have been built.
#
# Shims our moudules into gen_vimdoc_config.lua, replacing Nvim's.
#
# There are some hardcoded expectations which we work around as commented.

set -e

if [ ! -d "${NVIM_SRC}" ]; then
	cat << EOM

\$NVIM_SRC not set

Nvim source is required to run src/gen/gen_vimdoc.lua

Please:
  mkdir -p src
  curl -L 'https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz' | tar zx --directory src
  NVIM_SRC=src/neovim-stable ${0}
EOM
exit 1
fi

# runtime/doc is hardcoded, copy the help in
mkdir -pv runtime/doc
cp -v "doc/nvim-tree-lua.txt" runtime/doc

# modify gen_vimdoc.lua to use our config
cp -v "${NVIM_SRC}/src/gen/gen_vimdoc.lua" gen_vimdoc.lua
sed -i -E 's/spairs\(config\)/spairs\(require("gen_vimdoc_config")\)/g' gen_vimdoc.lua

# use luacacts etc. from neovim src as well as our specific config
export LUA_PATH="${NVIM_SRC}/src/?.lua;scripts/?.lua"

# generate
./gen_vimdoc.lua

# move the generated help out
mv -v "runtime/doc/nvim-tree-lua.txt" doc

# clean up
rmdir -v runtime/doc
rmdir -v runtime
rm -v gen_vimdoc.lua

