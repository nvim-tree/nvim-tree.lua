#!/usr/bin/env sh

# delete, create and return the absolute path of the directory to execute tests in
# /tmp/nvt_func is the base
# if data is present, recursively copy it into /tmp/nvt_func/data and return it
# otherwise return empty /tmp/nvt_func
#
# prints "DIR=/absolute/path" on success
#
# nvim 0.12 does not have access to vim.system, hence we must use vim.fn.system to execute this
# vim.fn.system cannot detect error codes in the test context, as vim.v is not available
# hence we must use the output to determine success

set -e

DIR="/tmp/nvt_func"

# blow away temp
rm -r -f "${DIR}"
mkdir -p "${DIR}"

# maybe copy entire data directory and use it
if [ -d "${NVT_FUNC_TEST_SOURCE}/data" ]; then
	cp -p -r "${NVT_FUNC_TEST_SOURCE}/data" "${DIR}"
	DIR="${DIR}/data"
fi

printf "DIR=${DIR}"
