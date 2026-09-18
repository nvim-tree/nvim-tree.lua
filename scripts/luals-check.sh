#!/usr/bin/env sh

# Performs a lua-language-server check.
# $VIMRUNTIME specifies neovim runtime path, defaults to "/usr/share/nvim/runtime" if unset.
# $DIR_NVIM_SRC will be checked and set for test files.
#
# Call with codestyle-check param to enable only codestyle-check
#
# lua-language-server is inconsisent about which parameters must be absolute paths therefore we pass every path as absolute

# TODO change to an optional -c argument
usage() {
	echo "usage: ${0} [codestyle-check] <lua|scripts|test>" 1>&2
}

if [ $# -eq 2 ]; then
	if [ "${1}" != "codestyle-check" ]; then
		usage
		exit 1
	fi
	STYLE=true
	shift
fi

case "${1}" in
	lua|scripts|test)
		TARGET="${1}"
		;;
	*)
		usage
		exit 0
		;;
esac

# neovim source needed for tests
if [ "${TARGET}" = "test" ]; then
	. scripts/check-nvim-src.sh
	export VIMRUNTIME="${DIR_NVIM_SRC}/runtime"
fi

DIR_NVT="${PWD}"

if [ ! -f "${DIR_NVT}/scripts/luals-check.sh" ]; then
	echo "Must be run from nvim-tree root" 1>&2
	exit 1
fi

if [ -z "${VIMRUNTIME}" ]; then
	export VIMRUNTIME="/usr/share/nvim/runtime"
	echo "Defaulting to VIMRUNTIME=${VIMRUNTIME}"
fi

if [ ! -d "${VIMRUNTIME}" ]; then
	echo "\$VIMRUNTIME=${VIMRUNTIME} not found" 1>&2
	exit 1
fi

DIR_OUT="${DIR_NVT}/luals-out"
LUARC="${DIR_OUT}/luarc.json"
RC=0

# clear previous output
rm -rf "${DIR_OUT}"
mkdir "${DIR_OUT}"

# create the luarc.json for the requested check
if [ -n "${STYLE}" ]; then
	jq \
		'.diagnostics.neededFileStatus[] = "None" | .diagnostics.neededFileStatus."codestyle-check" = "Any"' \
		"${DIR_NVT}/.luarc.json" > "${LUARC}"
else
	cp "${DIR_NVT}/.luarc.json" "${LUARC}"
fi

DIR_SRC="${DIR_NVT}/${TARGET}"
FILE_OUT="${DIR_OUT}/out.${TARGET}.log"
echo "Checking ${TARGET}/"

lua-language-server --check="${DIR_SRC}" --configpath="${LUARC}" --checklevel=Information --logpath="${DIR_OUT}" --loglevel=error 2>&1 | tee "${FILE_OUT}"

if ! grep --quiet "Diagnosis completed, no problems found" "${FILE_OUT}"; then
	RC=1
fi

exit "${RC}"
