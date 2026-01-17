#!/usr/bin/env sh

# Performs a lua-language-server check on all files.
# luals-out/check.json will be produced on any issues, returning 1.
# Outputs only check.json to stdout, all other messages to stderr, to allow jq etc.
# $VIMRUNTIME specifies neovim runtime path, defaults to "/usr/share/nvim/runtime" if unset.
#
# Call with codestyle-check param to enable only codestyle-check

if [ -z "${VIMRUNTIME}" ]; then
	export VIMRUNTIME="/usr/share/nvim/runtime"
fi

DIR_SRC="${PWD}/lua"
DIR_OUT="${PWD}/luals-out"
FILE_LUARC="${DIR_OUT}/luarc.json"

# clear output
rm -rf "${DIR_OUT}"
mkdir "${DIR_OUT}"

case "${1}" in
	"codestyle-check")
		echo "TODO #3088 skipping codestyle-check until api.lua refactor is complete"
		exit 0
		jq \
			'.diagnostics.neededFileStatus[] = "None" | .diagnostics.neededFileStatus."codestyle-check" = "Any"' \
			"${PWD}/.luarc.json" > "${FILE_LUARC}"

		;;
	*)
		cp "${PWD}/.luarc.json" "${FILE_LUARC}"
		;;
esac

# execute inside lua directory to prevent luals itself from being checked
OUT=$(lua-language-server --check="${DIR_SRC}" --configpath="${FILE_LUARC}" --checklevel=Information --logpath="${DIR_OUT}" --loglevel=error)
RC=$?

echo "${OUT}" >&2

if [ $RC -ne 0 ]; then
	echo "failed with RC=$RC"
	exit $RC
fi

# any output is a fail
case "${OUT}" in
	*Diagnosis\ completed,\ no\ problems\ found*)
		exit 0
		;;
	*)
		cat "${DIR_OUT}/check.json"
		exit 1
		;;
esac

