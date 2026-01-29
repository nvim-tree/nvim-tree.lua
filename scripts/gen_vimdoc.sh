#!/usr/bin/env sh

# Wrapper around Nvim help generator gen_vimdoc.lua, run as part of Nvim's make doc target.
#
# Doesn't require Nvim to have been built.
#
# Shims our moudules into gen_vimdoc_config.lua, replacing Nvim's.
#
# There are some hardcoded expectations which we work around as commented.

set -e

# unset to ensure no collisions with system installs etc.
unset VIMRUNTIME

# Use a directory outside of nvim_tree source. Adding lua files inside will (rightly) upset luals.
DIR_NVT="${PWD}"
DIR_WORK="/tmp/nvim-tree-gen_vimdoc"
DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

if [ ! -f "${DIR_NVT}/scripts/gen_vimdoc.sh" ]; then
	echo "Must be run from nvim-tree root" 1>&2
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

# clean up previous
rm -rfv "${DIR_WORK}"

# runtime/doc is hardcoded, copy the help in
mkdir -pv "${DIR_WORK}/runtime/doc"
cp -v "${DIR_NVT}/doc/nvim-tree-lua.txt" "${DIR_WORK}/runtime/doc"

# modify gen_vimdoc.lua to use our config
cp -v "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua" "${DIR_WORK}/gen_vimdoc.lua"
sed -i -E 's/spairs\(config\)/spairs\(require("gen_vimdoc_config")\)/g' "${DIR_WORK}/gen_vimdoc.lua"

# use luacacts etc. from neovim src as well as our specific config
export LUA_PATH="${DIR_NVIM_SRC}/src/?.lua;${DIR_NVT}/scripts/?.lua"

# gen_vimdoc.lua doesn't like dashes in lua module names
#   -> use nvim_tree instead of nvim-tree
mkdir -pv "${DIR_WORK}/runtime/lua"
ln -sv "${DIR_NVT}/lua/nvim-tree" "${DIR_WORK}/runtime/lua/nvim_tree"

# generate
cd "${DIR_WORK}" && pwd
./gen_vimdoc.lua
cd -

# copy the generated help out
cp -v "${DIR_WORK}/runtime/doc/nvim-tree-lua.txt" "${DIR_NVT}/doc"
