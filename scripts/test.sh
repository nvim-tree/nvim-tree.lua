#!/bin/sh

set -e

# TODO add ability for user to specify a test file or directory

# TODO clone plenary

DIR_REPO="$(git rev-parse --show-toplevel)"
export DIR_REPO

DIR_PLENARY="${DIR_REPO}/plenary.nvim"
export DIR_PLENARY

nvim --headless \
	--clean \
	-u "${DIR_REPO}/tests/minimal_init.lua" \
	-l "${DIR_REPO}/tests/test_init.lua" \
	-c "qa!"

