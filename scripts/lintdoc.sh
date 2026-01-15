#!/usr/bin/env sh

# Wrapper around Nvim help linter lintdoc.lua, run as part of Nvim's make lintdoc target.
#
# Requires Nvim to have been built.
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
  export NVIM_SRC=src/neovim-stable
EOM
exit 1
fi

# unset to ensure no collisions with system installs etc.
unset VIMRUNTIME

# runtime/doc in the Nvim source is practically hardcoded, copy our help in
cp -v "doc/nvim-tree-lua.txt" "${NVIM_SRC}/runtime/doc"

# run from within Nvim source
cd "${NVIM_SRC}"

# make nvim and execute the lint
make lintdoc
