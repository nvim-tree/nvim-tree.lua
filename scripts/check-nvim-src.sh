#!/usr/bin/env sh

# common script to check the availability of neovim source
# - NOP if $DIR_NVIM_SRC is defined
# - sets $DIR_NVIM_SRC to /tmp/src/neovim-stable if present
# - otherwise prompts with instructions 
# script must be sourced to receive the exported $DIR_NVIM_SRC

DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

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
