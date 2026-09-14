#!/usr/bin/env sh

# TODO this will be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

# code under test
DIR_NVT="${PWD}"

# neovim source
DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

# nvim-tree linked as a package for the tests to add before run
DIR_NVT_PACK="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

usage() {
	echo "Usage: $0 [-h] [-t <file>] [-d <dir>]"
	echo
	echo "    OPTION:"
	echo "        -t  Execute single test"
	echo "        -d  Execute all tests in dir"
	echo "        -h  Show this help"
}

files_test_add_dir() {
	find "${1}" -type f -iname '*lua' > /tmp/nvt_files_test
	while IFS= read -r f; do
		FILES_TEST="${FILES_TEST} ${f}"
	done < /tmp/nvt_files_test
	rm /tmp/nvt_files_test
}

while getopts "ht:d:" o; do
	case "$o" in
		h) 
			usage
			exit 0
			;;
		d) 
			files_test_add_dir "${OPTARG:-}"
			;;
		t) 
			FILES_TEST="${FILES_TEST} ${OPTARG:-}"
			;;
		\?)
			usage >&2
			exit 1
			;;
	esac
done

# run all tests if none specified
if [ -z "${FILES_TEST}" ]; then
	files_test_add_dir "test/func"
fi

# TODO extract common functionality from vimdoc.sh
if [ ! -d "${DIR_NVT}/lua/nvim-tree" ]; then
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

cleanup() {
	rm -fv "${DIR_NVT_PACK}"
}

prepare() {
	cd "${DIR_NVIM_SRC}"

	make

	ln -sv "${DIR_NVT}" "${DIR_NVT_PACK}"
}

cleanup

prepare

for f in ${FILES_TEST}; do
	make functionaltest TEST_FILE="${DIR_NVT_PACK}/${f}"
done

cleanup
