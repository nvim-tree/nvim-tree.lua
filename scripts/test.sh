#!/bin/sh

set -e

DIR_REPO="$(git rev-parse --show-toplevel)"
export DIR_REPO

DIR_PLENARY="${DIR_REPO}/plenary.nvim"
export DIR_PLENARY

if [ "${#}" -eq 1 ]; then
	TEST_NAME="${1}"
else
	TEST_NAME="tests"
fi
export TEST_NAME

nvim --headless \
	--clean \
	-u "${DIR_REPO}/tests/minimal_init.lua" \
	-l "${DIR_REPO}/tests/test_init.lua" \
	-c "qa!"

