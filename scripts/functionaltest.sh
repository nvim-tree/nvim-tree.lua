#!/usr/bin/env sh

# TODO this will be shipped as part of the vim runtime https://github.com/neovim/neovim/issues/34592

set -e

# code under test
DIR_NVT="${PWD}"

# neovim source
DIR_NVIM_SRC_DEF="/tmp/src/neovim-stable"

# nvim-tree linked as a package for the tests to add before run
DIR_NVT_PACK="${DIR_NVIM_SRC}/runtime/pack/dist/opt/nvim-tree.lua"

# working copy of test data
DIR_DATA_WORKING="/tmp/nvt_test_func/data"

usage() {
	echo "Usage: $0 [-h] [-t <file>] [-d <dir>] [-l <dir data>]"
	echo
	echo "    OPTION:"
	echo "        -t  Execute single test"
	echo "        -d  Execute all tests in dir"
	echo "        -l  Live environment in data"
	echo "        -h  Show this help"
}

files_test_add_dir() {
	find "${1}" -type f -iname '*lua' > /tmp/nvt_files_test
	while IFS= read -r f; do
		FILES_TEST="${FILES_TEST} ${f}"
	done < /tmp/nvt_files_test
	rm /tmp/nvt_files_test
}

while getopts "hl:t:d:" o; do
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
		l)
			DIR_LIVE="$(realpath "${OPTARG:-}")"
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

# run all tests if none specified
if [ -z "${FILES_TEST}" ]; then
	files_test_add_dir "test/func"
fi

cleanup() {
	rm -fv "${DIR_NVT_PACK}"
	rm -rf "$(dirname "${DIR_DATA_WORKING}")"
}

prepare() {
	mkdir -p "$(dirname "${DIR_DATA_WORKING}")"
	cd "${DIR_NVIM_SRC}"
	make
	ln -sv "${DIR_NVT}" "${DIR_NVT_PACK}"
	cd "${DIR_NVT}"
}

live() {
	# options extracted from testnvim.lua nvim_argv, nvim_set
	nvim \
		--clean \
		--noplugin \
		-u "${DIR_NVT}/test/func/init_live.lua" \
		-i NONE \
		--cmd "set shortmess+=IS background=light noswapfile noautoindent startofline laststatus=1 undodir=. directory=. viewdir=. backupdir=. belloff= wildoptions-=pum joinspaces noshowcmd noruler nomore redrawdebug=invalid shada=!,'100,<50,s10,h statusline=%<%f\ %{%nvim_eval_statusline('%h%w%m%r',\ {'maxwidth':\ 30}).width\ >\ 0\ ?\ '%h%w%m%r\ '\ :\ ''%}%=%{%\ &showcmdloc\ ==\ 'statusline'\ ?\ '%-10.S\ '\ :\ ''\ %}%{%\ exists('b:keymap_name')\ ?\ '<'..b:keymap_name..'>\ '\ :\ ''\ %}%{%\ &ruler\ ?\ (\ &rulerformat\ ==\ ''\ ?\ '%-14.(%l,%c%V%)\ %P'\ :\ &rulerformat\ )\ :\ ''\ %}" \
		--cmd "comclear | mapclear | mapclear!" \
		--cmd "set packpath^=${DIR_NVIM_SRC}/runtime/" \
		--cmd "lua dofile('${DIR_NVIM_SRC}/runtime/colors/vim.lua')" \
		--cmd "unlet g:colors_name"
}

execute() {
	NVT_TEST_FILE="${DIR_NVT_PACK}/${1}"

	# copy the data directory to work
	rm -rf "${DIR_DATA_WORKING}"
	DIR_TEST="$(dirname "${NVT_TEST_FILE}")"
	if [ -d "${DIR_TEST}/data" ]; then
		cp -pr "${DIR_TEST}/data" "${DIR_DATA_WORKING}"
		export NVT_TEST_DATA="${DIR_DATA_WORKING}"
	else
		export NVT_TEST_DATA=
	fi

	make functionaltest TEST_FILE="${NVT_TEST_FILE}"

	rm -rf "${DIR_DATA_WORKING}"
}

cleanup

prepare

if [ -n "${DIR_LIVE}" ]; then
	cd "${DIR_LIVE}"

	live
else
	cd "${DIR_NVIM_SRC}"

	for f in ${FILES_TEST}; do
		execute "${f}"
	done
fi

cleanup
