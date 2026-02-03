#!/usr/bin/env sh

# Wrapper around Nvim make targets:
#
# make doc - gen_vimdoc.lua
#   Generates doc/nvim-tree-lua.txt 
#   Uses nvim-tree sources defined in scripts/vimdoc_config.lua
#   Shims above into src/gen/gen_vimdoc.lua, replacing Nvim's config.
#
# make lintdoc - lintdoc.lua
#   Validates doc/nvim-tree-lua.txt 
#   Desired:
#   - tags valid
#   - links valid
#   Also:
#   - brand spelling, notably Nvim and Lua
#
# There are some hardcoded expectations which we work around as commented.

set -e

if [ $# -ne 1 ] || [ "${1}" != "doc" ] && [ "${1}" != "lintdoc" ]; then
	echo "usage: ${0} <doc|lintdoc>" 1>&2
	exit 1
fi

DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

if [ ! -d "lua/nvim-tree" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

if [ -z "${DIR_NVIM_SRC}" ] && [ -d "${DIR_NVIM_SRC_DEF}" ]; then
	export DIR_NVIM_SRC="${DIR_NVIM_SRC_DEF}"
fi

if [ ! -d "${DIR_NVIM_SRC}" ]; then
	cat << EOM

Nvim source v0.11+ is required to run ${0}

Unavailable: ${DIR_NVIM_SRC_DEF} or \$DIR_NVIM_SRC=${DIR_NVIM_SRC}

Please:
  mkdir -p ${DIR_NVIM_SRC_DEF}
  curl -L 'https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz' | tar zx --directory $(dirname "${DIR_NVIM_SRC_DEF}")
	or use your own e.g.
  export DIR_NVIM_SRC="\${HOME}/src/neovim"

EOM
exit 1
fi

cleanup() {
	# remove source link
	rm -fv "${DIR_NVIM_SRC}/runtime/lua/nvim_tree"

	# remove our config
	rm -fv "${DIR_NVIM_SRC}/src/gen/gen_vimdoc_nvim_tree.lua"

	# remove generated help
	rm -fv "${DIR_NVIM_SRC}/runtime/doc/nvim-tree-lua.txt"

	# revert generator if present
	if [ -f "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua.org" ]; then
		mv -v "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua.org" "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua"
	fi
}

# clean up any previous failed runs
cleanup

# runtime/doc is hardcoded, copy the help in
cp -v "doc/nvim-tree-lua.txt" "${DIR_NVIM_SRC}/runtime/doc"

# setup doc generation
if [ "${1}" = "doc" ]; then
	# runtime/lua is available, link our sources in there
	# gen_vimdoc.lua doesn't like dashes in lua module names
	#   -> use nvim_tree instead of nvim-tree
	ln -sv "${PWD}/lua/nvim-tree" "${DIR_NVIM_SRC}/runtime/lua/nvim_tree"

	# modify gen_vimdoc.lua to use our config, backing up original
	cp "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua" "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua.org"
	sed -i -E 's/spairs\(config\)/spairs\(require("gen.vimdoc_config")\)/g' "${DIR_NVIM_SRC}/src/gen/gen_vimdoc.lua"

	# copy our config
	cp -v "scripts/vimdoc_config.lua" "${DIR_NVIM_SRC}/src/gen"
fi

# run from within Nvim source
cd "${DIR_NVIM_SRC}"
make "${1}"
cd -

# copy the generated help out
cp -v "${DIR_NVIM_SRC}/runtime/doc/nvim-tree-lua.txt" "doc"

# cleanup as everything succeeded
cleanup
