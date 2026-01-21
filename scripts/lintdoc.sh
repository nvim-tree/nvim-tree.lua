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

# unset to ensure no collisions with system installs etc.
unset VIMRUNTIME

# Use a directory outside of nvim_tree source. Adding lua files inside will (rightly) upset luals.
DIR_NVT="${PWD}"
DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

if [ ! -f "${DIR_NVT}/scripts/lintdoc.sh" ]; then
	echo "Must be run from nvim-tree root"
	exit 1
fi

if [ -z "${DIR_NVIM_SRC}" ] && [ -d "${DIR_NVIM_SRC_DEF}" ]; then
	export DIR_NVIM_SRC="${DIR_NVIM_SRC_DEF}"
	echo "Assumed DIR_NVIM_SRC=${DIR_NVIM_SRC}"
fi

if [ ! -d "${DIR_NVIM_SRC}" ]; then
	cat << EOM

\$DIR_NVIM_SRC=${DIR_NVIM_SRC} not set or missing.

Nvim source is required to run ${0}

Please:
  mkdir -p ${DIR_NVIM_SRC_DEF}
  curl -L 'https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz' | tar zx --directory $(dirname "${DIR_NVIM_SRC_DEF}")
  export DIR_NVIM_SRC=/tmp/src/neovim-stable
EOM
exit 1
fi

# runtime/doc in the Nvim source is practically hardcoded, copy our help in
cp -v "${DIR_NVT}/doc/nvim-tree-lua.txt" "${DIR_NVIM_SRC}/runtime/doc"

# run from within Nvim source
cd "${DIR_NVIM_SRC}"

# make nvim and execute the lint
make lintdoc
