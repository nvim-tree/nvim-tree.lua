#!/usr/bin/env sh

# neovim func test driver, see test/func/README.md
# this will be eventually be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

# code under test
DIR_NVT="${PWD}"

# neovim source
DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

# nvim-tree linked as a package under source
DIR_NVT_PACK="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

# working directory to copy test data into
DIR_WORK="/tmp/nvt_test_func"

# absolute paths of test files under nvim source
FILES_TEST=

# live directory, must contain data
DIR_LIVE=

# optional test data directory exported for tests
NVT_DIR_TEST_DATA=

usage() {
	echo "Usage: ${0} [-h] [-t <file or dir>] [-l <dir>]"
	echo
	echo "    OPTION:"
	echo "        -t  Execute single test file or all in directory"
	echo "        -l  Live environment in test data directory"
	echo "        -h  Show this help"
}

# add a file or directory $1 to FILES_TEST
files_test_add() {
	if [ -f "${1}" ]; then
		FILES_TEST="${FILES_TEST} ${DIR_NVT_PACK}/${1}"
	elif [ -d "${1}" ]; then
		find "${1}" -type f -iname '*lua' -not -iname 'init_live.lua' > /tmp/nvt_files_test
		while IFS= read -r f; do
			FILES_TEST="${FILES_TEST} ${DIR_NVT_PACK}/${f}"
		done < /tmp/nvt_files_test
		rm /tmp/nvt_files_test
	else
		echo "${1} inexistent"
		exit 1
	fi
}

# create DIR_LIVE if data dir present next to file $1 or in directory $1
live_add() {
	if [ -f "${1}" ]; then
		DIR_LIVE="$(dirname "${1}")"
	else
		DIR_LIVE="${1}"
	fi

	if [ ! -d "${DIR_LIVE}/data" ]; then
		echo "${DIR_LIVE}/data inexistent"
		exit 1
	fi
}

while getopts "hl:t:" o; do
	case "$o" in
		h)
			usage
			exit 0
			;;
		l)
			live_add "${OPTARG:-}"
			;;
		t)
			files_test_add "${OPTARG:-}"
			;;
		\?)
			usage >&2
			exit 1
			;;
	esac
done

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

# after all tests
teardown() {
	rm -fv "${DIR_NVT_PACK}"
	rm -rf "${DIR_WORK}"
}

# before all tests: builds nvim and links nvim-tree as a package under nvim source
setup() {
	cd "${DIR_NVIM_SRC}"
	make
	ln -sv "${DIR_NVT}" "${DIR_NVT_PACK}"
	cd "${DIR_NVT}"
}

# if present, copies data directory in $1 to $DIR_WORK/data and sets $NVT_DIR_TEST_DATA
before_each() {
	rm -rf "${DIR_WORK}"
	mkdir -p "${DIR_WORK}"
	if [ -d "${1}/data" ]; then
		cp -pr "${1}/data" "${DIR_WORK}"
		export NVT_DIR_TEST_DATA="${DIR_WORK}/data"
	else
		export NVT_DIR_TEST_DATA=
	fi
}

live() {
	# options extracted from testnvim.lua nvim_argv, nvim_set
	nvim \
		--clean \
		--noplugin \
		-u "${DIR_NVT_PACK}/test/func/init_live.lua" \
		-i NONE \
		--cmd "set shortmess+=IS background=light noswapfile noautoindent startofline laststatus=1 undodir=. directory=. viewdir=. backupdir=. belloff= wildoptions-=pum joinspaces noshowcmd noruler nomore redrawdebug=invalid shada=!,'100,<50,s10,h statusline=%<%f\ %{%nvim_eval_statusline('%h%w%m%r',\ {'maxwidth':\ 30}).width\ >\ 0\ ?\ '%h%w%m%r\ '\ :\ ''%}%=%{%\ &showcmdloc\ ==\ 'statusline'\ ?\ '%-10.S\ '\ :\ ''\ %}%{%\ exists('b:keymap_name')\ ?\ '<'..b:keymap_name..'>\ '\ :\ ''\ %}%{%\ &ruler\ ?\ (\ &rulerformat\ ==\ ''\ ?\ '%-14.(%l,%c%V%)\ %P'\ :\ &rulerformat\ )\ :\ ''\ %}" \
		--cmd "comclear | mapclear | mapclear!" \
		--cmd "set packpath^=${DIR_NVIM_SRC}/runtime/" \
		--cmd "lua dofile('${DIR_NVIM_SRC}/runtime/colors/vim.lua')" \
		--cmd "unlet g:colors_name"
}

teardown

setup

if [ -n "${DIR_LIVE}" ]; then
	before_each "${DIR_LIVE}"

	live
else
	# run all tests if none specified
	if [ -z "${FILES_TEST}" ]; then
		files_test_add "test/func"
	fi

	# run from nvim source root
	cd "${DIR_NVIM_SRC}"

	# execute all tests
	for f in ${FILES_TEST}; do
		before_each "$(dirname "${f}")"

		make functionaltest TEST_FILE="${f}"
	done
fi

teardown
