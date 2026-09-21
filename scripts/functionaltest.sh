#!/usr/bin/env sh

# neovim func test driver, see test/func/README.md
# this will be eventually be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

if [ ! -d "test/func" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

# define $DIR_NVIM_SRC
. scripts/check-nvim-src.sh

# code under test
DIR_NVT="${PWD}"

# nvim-tree linked as a package under source
DIR_NVT_PACK="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

# absolute paths of test files under nvim source
FILES_TEST=

# live source directory
DIR_LIVE=

# working directory for tests, which are responsible for creating and removing
export NVT_FUNC_TMP="/tmp/nvt_func"

# test source, which tests may copy data from
export NVT_FUNC_SRC=

usage() {
	echo "Usage: ${0} [-h] [-t <file or dir>] [-l <file or dir>]"
	echo
	echo "    OPTION:"
	echo "        -t  Execute single test file or all in directory"
	echo "        -l  Live environment in test's data directory"
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

# set DIR_LIVE for directory or test file
live_add() {
	if [ -f "${1}" ]; then
		DIR_LIVE="$(dirname "${1}")"
	else
		DIR_LIVE="${1}"
	fi

	DIR_LIVE="$(realpath "${DIR_LIVE}")"

	if [ ! -d "${DIR_LIVE}" ]; then
		echo "${DIR_LIVE} inexistent"
		exit 1
	fi
}

# TODO fail on scripts/functionaltest.sh foo
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

# before all tests: links nvim-tree as a package under nvim source
setup() {
	ln -sv "${DIR_NVT}" "${DIR_NVT_PACK}"
}

# after all tests: remove package link and temp
teardown() {
	rm -fv "${DIR_NVT_PACK}"
	rm -rf "${NVT_FUNC_TMP}"
}

live() {
	NVT_FUNC_SRC="${DIR_LIVE}"

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
	live
else
	# run all tests if none specified
	if [ -z "${FILES_TEST}" ]; then
		files_test_add "test/func"
	fi

	# must run from nvim source root
	cd "${DIR_NVIM_SRC}"

	# execute all tests
	for f in ${FILES_TEST}; do
		NVT_FUNC_SRC="$(dirname "${f}")"
		make functionaltest TEST_FILE="${f}"
	done
fi

teardown
