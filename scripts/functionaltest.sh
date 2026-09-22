#!/usr/bin/env sh

# neovim func test driver, see test/func/README.md
# this will be eventually be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

if [ ! -d "test/functional/nvt" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

# define $DIR_NVIM_SRC
. scripts/check-nvim-src.sh

# code under test
DIR_NVT="${PWD}"

# nvim-tree linked as a package under source
DIR_NVT_PACK="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

# test spec files to execute, relative to neovim source
FILES_TEST=

# live source directory
DIR_LIVE=

# working directory for tests, which are responsible for creating and removing
NVT_FUNC_TMP="/tmp/nvt_func"

# optional test data
NVT_FUNC_DATA=

usage() {
	echo "Usage: ${0} [-h] [-t <file or dir>] [-l [<dir>]]"
	echo
	echo "    OPTION:"
	echo "        -t  Execute single test file or all in directory"
	echo "        -l  Live environment, optionally using a test's data"
	echo "        -h  Show this help"
}

# add a file or directory $1 to FILES_TEST
files_test_add() {
	echo "files_test_add ${1}"
	if [ -f "${1}" ]; then
		FILES_TEST="${FILES_TEST} ${1}"
	elif [ -d "${1}" ]; then
		find "${1}" -type f -iname '*_spec.lua' > /tmp/nvt_files_test
		while IFS= read -r f; do
			FILES_TEST="${FILES_TEST} ${f}"
		done < /tmp/nvt_files_test
		rm /tmp/nvt_files_test
	else
		echo "${1} inexistent"
		exit 1
	fi
}

# set DIR_LIVE for directory or test file
live_add() {
	DIR_LIVE="${1}"
	if [ ! -d "${DIR_LIVE}" ]; then
		echo "${DIR_LIVE} inexistent"
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
		*)
			usage >&2
			exit 1
			;;
	esac
done

# before all tests: links nvim-tree lua and test under
setup() {
	mkdir -p "${DIR_NVT_PACK}"
	ln -sv "${DIR_NVT}/lua" "${DIR_NVT_PACK}"

	ln -sv "${DIR_NVT}/test/functional/nvt" "${DIR_NVIM_SRC}/test/functional"
}

# after all tests: remove lua/test links and temp
teardown() {
	rm -fv "${DIR_NVIM_SRC}/test/functional/nvt"

	rm -fv "${DIR_NVT_PACK}/lua"
	rm -rf "${DIR_NVT_PACK}"
}

# export variables for individual test
before_each() {
	# test will execute in this directory
	rm -rf "${NVT_FUNC_TMP}"
	export NVT_FUNC_TMP

	# test will recursively copy data if it exists
	NVT_FUNC_DATA="$(realpath "$(dirname "${1}")/data")"
	if [ -d "${NVT_FUNC_DATA}" ]; then
		export NVT_FUNC_DATA
	else
		unset NVT_FUNC_DATA
	fi
}

live() {
	before_each "${DIR_LIVE}"

	# options extracted from testnvim.lua nvim_argv, nvim_set
	nvim \
		--clean \
		--noplugin \
		-u "${DIR_NVIM_SRC}/test/functional/nvt/init_live.lua" \
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
	live
else
	# run all tests if none specified
	if [ -z "${FILES_TEST}" ]; then
		files_test_add "test/functional/nvt"
	fi

	# cmake must be run from nvim source root
	cd "${DIR_NVIM_SRC}"

	# execute all tests
	for f in ${FILES_TEST}; do
		before_each "${f}"
		make functionaltest TEST_FILE="${f}"
	done
fi

teardown
