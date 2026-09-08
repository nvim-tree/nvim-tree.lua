#!/usr/bin/env sh

set -e

# neovim source
DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

cleanup() {
	rm -fv "${DIR_NVT_PACK}"
}

# TODO extract common functionality from vimdoc.sh
if [ ! -d "lua/nvim-tree" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

if [ -z "${DIR_NVIM_SRC}" ] && [ -d "${DIR_NVIM_SRC_DEF}" ]; then
	export DIR_NVIM_SRC="${DIR_NVIM_SRC_DEF}"
fi

if [ ! -d "${DIR_NVIM_SRC}" ]; then
	cat << EOM

Nvim stable source is required to run ${0}

Unavailable: ${DIR_NVIM_SRC_DEF} or \$DIR_NVIM_SRC=${DIR_NVIM_SRC}

Please:
  mkdir -p ${DIR_NVIM_SRC_DEF}
  curl -L 'https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz' | tar zx --directory $(dirname "${DIR_NVIM_SRC_DEF}")
	or use your own e.g.
  export DIR_NVIM_SRC="\${HOME}/src/neovim"

EOM
exit 1
fi

# nvim-tree linked as a package for the tests to add before run
DIR_NVT_PACK="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

cleanup

ln -sv "${PWD}" "${DIR_NVT_PACK}"

cd "${DIR_NVIM_SRC}"

make functionaltest TEST_FILE="${DIR_NVT_PACK}/test/func/api/open.lua"

cd -

cleanup
