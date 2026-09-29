#!/usr/bin/env sh

# neovim func test driver, see test/func/README.md
# exits with number of tests failed
# this will be eventually be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

if [ ! -d "test/functional/nvt" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

# define $DIR_NVIM_SRC
. scripts/check-nvim-src.sh

# root of code under test
dir_nvt="${PWD}"

# nvim-tree linked as a package under source
dir_nvt_pack="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

# nvim-tree linked under the neovim source: under src (not test) to prevent luals from finding it
# this is necessary so that the test may be found relative to test startup directory build/Xtest_xdg, which contains only links to runtime, src and test
dir_nvt_linked="${DIR_NVIM_SRC}/src/nvt"

# test spec files to execute, relative to $dir_nvt
files_test_lua=

# live data directory or "none"
dir_live=

# number of test failures
failures=0

# add absolute paths of linked nvim-tree source to test environment so that tests themselves may access it
test_args="--lpath=${dir_nvt_linked}/?.lua --lpath=${dir_nvt_linked}/lua/?.lua --lpath=${dir_nvt_linked}/lua/?/init.lua"

# absolute path of the source: $dir_nvt
export NVT_FUNC_DIR_ROOT="${dir_nvt}"

# absolute path of the test directory, under $dir_nvt
export NVT_FUNC_DIR_TEST=

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
# setup
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
		files_test_lua="${files_test_lua} ${1}"
	elif [ -d "${1}" ]; then
		find "${1}" -type f -iname '*_spec.lua' > /tmp/nvt_files_test_lua
		while IFS= read -r f; do
			files_test_lua="${files_test_lua} ${f}"
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

# before all tests: links plugin and tests in their appropriate places under neovim source
setup() {
	teardown

	# complete nvim-tree source
	ln -sv "${dir_nvt}" "${dir_nvt_linked}"

	# TODO can we relocate this to a distinct packpath?
	# plugin runtime package
	mkdir -pv "${dir_nvt_pack}"
	ln -sv "${dir_nvt}/doc" "${dir_nvt_pack}"
	ln -sv "${dir_nvt}/lua" "${dir_nvt_pack}"
	ln -sv "${dir_nvt}/plugin" "${dir_nvt_pack}"
}

# after all tests: remove plugin and test links from neovim source
teardown() {
	# plugin runtime package
	rm -fv "${dir_nvt_pack}/doc"
	rm -fv "${dir_nvt_pack}/lua"
	rm -fv "${dir_nvt_pack}/plugin"
	rm -rf "${dir_nvt_pack}"

	# complete nvim-tree source
	rm -fv  "${dir_nvt_linked}"
}

# TODO could this completely bypass setup?
live() {
	if [ "${dir_live}" != "none" ]; then
		NVT_FUNC_DIR_TEST="$(realpath "$(dirname "${dir_live}")")"
	fi

	# options extracted from testnvim.lua nvim_argv, nvim_set
	nvim \
		--clean \
		--noplugin \
		-u "test/functional/nvt/init_live.lua" \
		-i NONE \
		--cmd "set shortmess+=IS background=light noswapfile noautoindent startofline laststatus=1 undodir=. directory=. viewdir=. backupdir=. belloff= wildoptions-=pum joinspaces noshowcmd noruler nomore redrawdebug=invalid shada=!,'100,<50,s10,h statusline=%<%f\ %{%nvim_eval_statusline('%h%w%m%r',\ {'maxwidth':\ 30}).width\ >\ 0\ ?\ '%h%w%m%r\ '\ :\ ''%}%=%{%\ &showcmdloc\ ==\ 'statusline'\ ?\ '%-10.S\ '\ :\ ''\ %}%{%\ exists('b:keymap_name')\ ?\ '<'..b:keymap_name..'>\ '\ :\ ''\ %}%{%\ &ruler\ ?\ (\ &rulerformat\ ==\ ''\ ?\ '%-14.(%l,%c%V%)\ %P'\ :\ &rulerformat\ )\ :\ ''\ %}" \
		--cmd "comclear | mapclear | mapclear!" \
		--cmd "set packpath^=${DIR_NVIM_SRC}/runtime/" \
		--cmd "lua dofile('${DIR_NVIM_SRC}/runtime/colors/vim.lua')" \
		--cmd "unlet g:colors_name" \
		|| failures=1
}

files_test_lua_execute() {
	# cmake must be run from nvim source root
	cd "${DIR_NVIM_SRC}"

	# execute all requested tests
	for f in ${files_test_lua}; do
		file_test_lua="${dir_nvt_linked}/${f}"

		NVT_FUNC_DIR_TEST="$(dirname "${file_test_lua}")"

		# don't exit on failure, just note it
		make functionaltest TEST_ARGS="${test_args}" TEST_FILE="${file_test_lua}" || failures=$((failures + 1))
	done
}

#
# act
#

setup

case "${mode}" in
	l)
		live
		;;
	a|t)
		files_test_lua_execute
		;;
	*)
		;;
esac

teardown

exit "${failures}"
