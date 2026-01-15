#!/usr/bin/env sh

# Wrapper around nvim help linter lintdoc.lua, run as part of nvim's make lintdoc target.
#
# Requires nvim to have been built.
#
# Desired:
# - tags valid
# - links valid
# Also:
# - brand spelling, notably Nvim and Lua
#
# There are some hardcoded expectations which we work around as commented.

set -e

if [ ! -d "${NVIM_SRC}" ]; then
	cat << EOM

\$NVIM_SRC not set

Compiled Nvim source is required to run src/gen/gen_vimdoc.lua

Please:
  mkdir -p src
  curl -L 'https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz' | tar zx --directory src
  NVIM_SRC=src/neovim-stable ${0}
EOM
exit 1
fi

# runtime/doc in the nvim source is practically hardcoded, copy our help in
cp -v "doc/nvim-tree-lua.txt" "${NVIM_SRC}/runtime/doc"

# run from within nvim source
cd "${NVIM_SRC}"

# make nvim 
make

# execute the lint
VIMRUNTIME=runtime scripts/lintdoc.lua
