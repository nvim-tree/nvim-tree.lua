#!/usr/bin/env sh

# Nvim func test driver, see test/func/README.md
# exits with number of tests failed
# this will be eventually be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

if [ ! -d "test/nvt/func" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

# define $DIR_NVIM_SRC
. scripts/check-nvim-src.sh

# absolute path of nvim-tree source
export NVT_DIR_SRC="${PWD}"

# TODO just hardcode this
# absolute path of the test instance cwd
export NVT_FUNC_DIR_CWD="/tmp/nvt_func"

# optional argument of -l
export NVT_DIR_LIVE=

# parent directory under which nvim-tree is linked under Nvim source
# uses src (not test or runtime) to prevent luals from finding it 
# src can be found in build/Xtest_xdg, which contains only links to runtime, src and test
# pack/dist/opt is added underneath to satisfy :packadd convention
export NVT_FUNC_PACKPATH="${DIR_NVIM_SRC}/src/nvt"

# passed to make functionaltest; underneath Nvim source
export TEST_FILE=

# absolute link to nvim-tree source root under Nvim source
dir_src_linked="${NVT_FUNC_PACKPATH}/pack/dist/opt/nvim-tree.lua"

# number of test failures
failures=0

# a, t or l
mode=

# TODO clarify messages
usage() {
	echo "Usage: ${0} [-a] [-h] [-t <file or dir>] [-l [<data dir>]]"
	echo
	echo "    OPTION:"
	echo "        -a  Execute all tests"
	echo "        -t  Executes single test file or all under directory, passed as TEST_FILE to Nvim make functionaltest"
	echo "        -l  Live environment, optionally using a data directory"
	echo "        -h  Show this help"
}

#
# CLI args
#

# TODO remove, this is too complex
# set $mode to $1, fail if another $mode already set 
mode_set() {
	if [ -n "${mode}" ] && [ "${mode}" != "${1}" ]; then
		echo "specify only one of -a, -t or -l" >&2
		exit 1
	fi
	mode="${1}"
}

while getopts "ahlt:" o; do
	case "${o}" in
		a)
			mode_set "${o}"
			TEST_FILE="${dir_src_linked}/test/nvt/func"
			;;
		h)
			usage
			exit 0
			;;
		l)
			shift
			mode_set "${o}"
			NVT_DIR_LIVE="${1}"
			;;
		t)
			mode_set "${o}"
			TEST_FILE="${dir_src_linked}/${OPTARG}"
			;;
		*)
			usage >&2
			exit 1
			;;
	esac
done
if [ -z "${mode}" ]; then
	usage >&2
	exit 1
fi

#
# test harness
#

# before all tests: links plugin and tests in their appropriate places under Nvim source root
setup() {
	teardown

	# nvim-tree source link
	mkdir -p "$(dirname "${dir_src_linked}")"
	ln -sv "${PWD}" "${dir_src_linked}"
}

# after all tests: remove plugin and test links from Nvim source root
teardown() {
	# nvim-tree source link
	rm -fv  "${dir_src_linked}"

	# test/live instance cwd
	rm -rf "${NVT_FUNC_DIR_CWD}"
}

# TODO run with the compiled nvim version under test
live() {
	nvim \
		--clean \
		--noplugin \
		-u "test/nvt/func/init_live.lua" \
		-i NONE \
		--cmd "set shortmess+=IS background=light noswapfile noautoindent startofline laststatus=1 undodir=. directory=. viewdir=. backupdir=. belloff= wildoptions-=pum joinspaces noshowcmd noruler nomore redrawdebug=invalid shada=!,'100,<50,s10,h statusline=%<%f\ %{%nvim_eval_statusline('%h%w%m%r',\ {'maxwidth':\ 30}).width\ >\ 0\ ?\ '%h%w%m%r\ '\ :\ ''%}%=%{%\ &showcmdloc\ ==\ 'statusline'\ ?\ '%-10.S\ '\ :\ ''\ %}%{%\ exists('b:keymap_name')\ ?\ '<'..b:keymap_name..'>\ '\ :\ ''\ %}%{%\ &ruler\ ?\ (\ &rulerformat\ ==\ ''\ ?\ '%-14.(%l,%c%V%)\ %P'\ :\ &rulerformat\ )\ :\ ''\ %}" \
		--cmd "comclear | mapclear | mapclear!" \
		--cmd "set packpath^=${NVT_FUNC_PACKPATH}" \
		--cmd "lua dofile('${DIR_NVIM_SRC}/runtime/colors/vim.lua')" \
		--cmd "unlet g:colors_name" \
		--cmd "packadd nvim-tree.lua" \
		|| failures=1
}

run_tests() {
	# cmake must be run from nvim source root
	cd "${DIR_NVIM_SRC}"

	# export TEST_COLOURS=false

	# append nvim-tree lua/test to package.path, so that tests themselves may access nvim-tree source
	export TEST_ARGS="--lpath=${dir_src_linked}/?.lua --lpath=${dir_src_linked}/lua/?.lua --lpath=${dir_src_linked}/lua/?/init.lua"

	# don't exit on failure, just note it
	make functionaltest || failures=$((failures + 1)) 
}

#
# execute
#

setup

case "${mode}" in
	l)
		live
		;;
	a|t)
		run_tests
		;;
	*)
		;;
esac

teardown

exit "${failures}"
