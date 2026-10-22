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

# parent directory under which nvim-tree is linked under Nvim source
# uses src (not test or runtime) to prevent luals from finding it 
# src can be found in build/Xtest_xdg, which contains only links to runtime, src and test
# pack/dist/opt is added underneath to satisfy :packadd convention
export NVT_FUNC_PACKPATH="${DIR_NVIM_SRC}/src/nvt"

# used by make functionaltest; underneath Nvim source
export TEST_FILE=

# optional argument of -l
NVT_DIR_LIVE=

# absolute link to nvim-tree source root under Nvim source
dir_src_linked="${NVT_FUNC_PACKPATH}/pack/dist/opt/nvim-tree.lua"

# $RC from tests/live, returned after teardown
rc=0

usage() {
	echo "Usage: ${0} [-a] [-h] [-t <file or dir>] [-l [<data dir>]]"
	echo
	echo "    OPTION:"
	echo "        -a  Execute all tests"
	echo "        -t  Executes single test file or all under directory, passed as TEST_FILE to Nvim make functionaltest"
	echo "        -l  Live environment, optionally using a data directory"
	echo "        -h  Show this help"
}

# before all tests: links nvim-tree under Nvim source
setup() {
	teardown

	# nvim-tree source link
	mkdir -p "$(dirname "${dir_src_linked}")"
	ln -s "${PWD}" "${dir_src_linked}"
}

# after all tests: remove links and test instance directory
teardown() {
	# nvim-tree source link
	rm -f  "${dir_src_linked}"

	# test/live instance cwd
	rm -rf "/tmp/nvt_func"
}

# start a live Nvim session for generating test data
# $1: optional $NVT_DIR_LIVE
live() {
	if [ -n "${1}" ]; then
		rel="$(realpath --relative-to "${PWD}" "${1}")"
		if [ ! -d "${rel}" ]; then
			printf "%s inexistent\n" "${1}" 1>&2
			exit 1
		fi
		export NVT_DIR_LIVE="${rel}"
	fi

	setup

	export VIMRUNTIME="${DIR_NVIM_SRC}/runtime"

	"${DIR_NVIM_SRC}/build/bin/nvim" \
		--clean \
		--noplugin \
		-u "test/nvt/func/init_live.lua" \
		-i NONE \
		--cmd "set shortmess+=IS background=light noswapfile noautoindent startofline laststatus=1 undodir=. directory=. viewdir=. backupdir=. belloff= wildoptions-=pum joinspaces noshowcmd noruler nomore redrawdebug=invalid shada=!,'100,<50,s10,h statusline=%<%f\ %{%nvim_eval_statusline('%h%w%m%r',\ {'maxwidth':\ 30}).width\ >\ 0\ ?\ '%h%w%m%r\ '\ :\ ''%}%=%{%\ &showcmdloc\ ==\ 'statusline'\ ?\ '%-10.S\ '\ :\ ''\ %}%{%\ exists('b:keymap_name')\ ?\ '<'..b:keymap_name..'>\ '\ :\ ''\ %}%{%\ &ruler\ ?\ (\ &rulerformat\ ==\ ''\ ?\ '%-14.(%l,%c%V%)\ %P'\ :\ &rulerformat\ )\ :\ ''\ %}" \
		--cmd "comclear | mapclear | mapclear!" \
		--cmd "set packpath^=${NVT_FUNC_PACKPATH}" \
		--cmd "lua dofile('${VIMRUNTIME}/colors/vim.lua')" \
		--cmd "unlet g:colors_name" \
		--cmd "packadd nvim-tree.lua" \
		|| rc=$?

	teardown
}

# execute make functionaltest, exporting necessary TEST_* variables
# $1: TEST_FILE relative path
make_functionaltest() {
	rel="$(realpath --relative-to "${PWD}" "${1}")"
	if [ ! -f "${rel}" ] && [ ! -d "${rel}" ]; then
		printf "%s inexistent\n" "${1}" 1>&2
		exit 1
	fi

	setup

	export TEST_FILE="${dir_src_linked}/${1}"

	# append nvim-tree lua/test to package.path, so that tests themselves may access nvim-tree source
	export TEST_ARGS="--lpath=${dir_src_linked}/?.lua --lpath=${dir_src_linked}/lua/?.lua --lpath=${dir_src_linked}/lua/?/init.lua"

	# export TEST_COLORS=false

	# cmake must be run from nvim source root
	cd "${DIR_NVIM_SRC}"

	# don't exit on failure, just note it
	make functionaltest || rc=$?

	teardown
}

if [ ${#} -lt 1 ]; then
	usage >&2
	exit 1
fi
while getopts "ahlt:" o; do
	case "${o}" in
		a)
			make_functionaltest "test/nvt/func"
			;;
		h)
			usage
			exit 0
			;;
		l)
			shift
			live "${1}"
			;;
		t)
			make_functionaltest "${OPTARG}"
			;;
		*)
			usage >&2
			exit 1
			;;
	esac
done

exit "${rc}"
