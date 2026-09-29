#!/usr/bin/env sh

# Nvim func test driver, see test/func/README.md
# exits with number of tests failed
# this will be eventually be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

if [ ! -d "test/functional/nvt" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

# define $DIR_NVIM_SRC
. scripts/check-nvim-src.sh

# parent directory under which nvim-tree is linked under Nvim source
# uses src (not test or runtime) to prevent luals from finding it 
# src can be found in build/Xtest_xdg, which contains only links to runtime, src and test
# pack/dist/opt is added underneath to satisfy :packadd convention
export NVT_FUNC_PACKPATH="${DIR_NVIM_SRC}/src/nvt"

# absolute link to nvim-tree source root under Nvim source
export NVT_FUNC_DIR_ROOT="${NVT_FUNC_PACKPATH}/pack/dist/opt/nvim-tree.lua"

# absolute path of the test's directory under Nvim source
export NVT_FUNC_DIR_TEST=

# absolute path of script to execute to setup the test execution directory
export NVT_FUNC_SCRIPT_CREATE_TEST_CWD="${NVT_FUNC_DIR_ROOT}/test/functional/nvt/create_test_cwd.sh"

# absolute paths of test spec files to execute, under Nvim source
files_test_lua=

# live data directory or "none", empty when -l not specified
dir_live=

# number of test failures
failures=0

# a, t or l
mode=

usage() {
	echo "Usage: ${0} [-a] [-h] [-t <file or dir>] [-l [<data dir>]]"
	echo
	echo "    OPTION:"
	echo "        -a  Execute all tests"
	echo "        -t  Execute single test file or all under directory"
	echo "        -l  Live environment, optionally using a data directory"
	echo "        -h  Show this help"
}

#
# CLI args
#

# set $mode to $1, fail if another $mode already set 
mode_set() {
	if [ -n "${mode}" ] && [ "${mode}" != "${1}" ]; then
		echo "specify only one of -a, -t or -l" >&2
		exit 1
	fi
	mode="${1}"
}

# add a single file $1 or all _spec.lua files under directory $1 to $files_test_lua
files_test_lua_add() {
	if [ -f "${1}" ]; then
		files_test_lua="${files_test_lua} ${NVT_FUNC_DIR_ROOT}/${1}"
	elif [ -d "${1}" ]; then
		find "${1}" -type f -iname '*_spec.lua' > /tmp/nvt_files_test_lua
		while IFS= read -r f; do
			files_test_lua="${files_test_lua} ${NVT_FUNC_DIR_ROOT}/${f}"
		done < /tmp/nvt_files_test_lua
		rm /tmp/nvt_files_test_lua
	else
		echo "${1} inexistent" >&2
		exit 1
	fi
	if [ -z "${files_test_lua}" ]; then
		echo "no tests found in ${1}" >&2
		exit 1
	fi
}

# set $dir_live to directory or "none"
dir_live_set() {
	if [ -n "${1}" ]; then
		dir_live="${1}"
		if [ ! -d "${dir_live}" ]; then
			echo "${dir_live} inexistent" >&2
			exit 1
		fi
		if [ "$(basename "${dir_live}")" != "data" ]; then
			echo "${dir_live} not a directory named data" >&2
			exit 1
		fi
	else
		dir_live="none"
	fi
}

while getopts "ahlt:" o; do
	case "${o}" in
		a)
			mode_set "${o}"
			files_test_lua_add "test/functional/nvt"
			;;
		h)
			usage
			exit 0
			;;
		l)
			shift
			mode_set "${o}"
			dir_live_set "${1}"
			;;
		t)
			mode_set "${o}"
			files_test_lua_add "${OPTARG}"
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
	mkdir -p "$(dirname "${NVT_FUNC_DIR_ROOT}")"
	ln -sv "${PWD}" "${NVT_FUNC_DIR_ROOT}"
}

# after all tests: remove plugin and test links from Nvim source root
teardown() {
	# nvim-tree source link
	rm -fv  "${NVT_FUNC_DIR_ROOT}"
}

live() {
	if [ "${dir_live}" != "none" ]; then
		NVT_FUNC_DIR_TEST="$(dirname "${dir_live}")"
	fi

	# options extracted from testnvim.lua nvim_argv, nvim_set
	nvim \
		--clean \
		--noplugin \
		-u "test/functional/nvt/init_live.lua" \
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

	# execute all requested tests
	for f in ${files_test_lua}; do
		NVT_FUNC_DIR_TEST="$(dirname "${f}")"

		# append nvim-tree lua/test to package.path, so that tests themselves may access nvim-tree source
		# don't exit on failure, just note it
		make functionaltest \
			TEST_FILE="${f}" \
			TEST_ARGS="--lpath=${NVT_FUNC_DIR_ROOT}/?.lua --lpath=${NVT_FUNC_DIR_ROOT}/lua/?.lua --lpath=${NVT_FUNC_DIR_ROOT}/lua/?/init.lua" \
			|| failures=$((failures + 1)) 
		done
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
