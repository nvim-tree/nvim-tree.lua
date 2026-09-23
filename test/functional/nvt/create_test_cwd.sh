#!/usr/bin/env sh

# delete, create and return the absolute path of the directory to execute tests in
# $NVT_FUNC_TMP is the base
# if data is present, recursively copy it into $NVT_FUNC_TMP/data and return it
# otherwise return empty $NVT_FUNC_TMP
#
# prints "PATH=/absolute/path" on success
#
# nvim 0.12 does not have access to vim.system, hence we must use vim.fn.system to execute this
# vim.fn.system cannot detect error codes in the test context, as vim.v is not available
# hence we must use the output to determine success

set -e

if [ -z "${NVT_FUNC_TMP}" ]; then
	echo "\$NVT_FUNC_TMP not set"
	exit 1
fi

# blow away temp
rm -r -f "${NVT_FUNC_TMP}"
mkdir -p "${NVT_FUNC_TMP}"

# maybe copy entire data directory
if [ -n "${NVT_FUNC_DATA}" ]; then
	if [ ! -d "${NVT_FUNC_DATA}" ]; then
		echo "\$NVT_FUNC_DATA inexistent: ${NVT_FUNC_DATA}"
	else
		cp -p -r "${NVT_FUNC_DATA}" "${NVT_FUNC_TMP}"
	fi
fi

printf "PATH=${NVT_FUNC_TMP}/data"
