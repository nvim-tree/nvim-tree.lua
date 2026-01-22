#!/usr/bin/env sh

# Performs a lua-language-server check on all lua files.
# $VIMRUNTIME specifies neovim runtime path, defaults to "/usr/share/nvim/runtime" if unset.
#
# Call with codestyle-check param to enable only codestyle-check
#
# lua-language-server is inconsisent about which parameters must be absolute paths therefore we pass every path as absolute

if [ $# -eq 1 ] && [ "${1}" != "codestyle-check" ] || [ $# -gt 1 ] ; then
	echo "usage: ${0} [codestyle-check]" 1>&2
	exit 1
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
case "${1}" in
	"codestyle-check")
		jq \
			'.diagnostics.neededFileStatus[] = "None" | .diagnostics.neededFileStatus."codestyle-check" = "Any"' \
			"${DIR_NVT}/.luarc.json" > "${LUARC}"

		;;
	*)
		cp "${DIR_NVT}/.luarc.json" "${LUARC}"
		;;
esac

for SRC in lua scripts; do
	DIR_SRC="${DIR_NVT}/${SRC}"
	FILE_OUT="${DIR_OUT}/out.${SRC}.log"
	echo "Checking ${SRC}/"

	lua-language-server --check="${DIR_SRC}" --configpath="${LUARC}" --checklevel=Information --logpath="${DIR_OUT}" --loglevel=error 2>&1 | tee "${FILE_OUT}"

	if ! grep --quiet "Diagnosis completed, no problems found" "${FILE_OUT}"; then
		RC=1
	fi
done

exit "${RC}"
