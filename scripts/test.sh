#!/bin/sh

set -e

# TODO add ability for user to specify a test file or directory

REPO_DIR="$(git rev-parse --show-toplevel)"
PLENARY_DIR="${REPO_DIR}/plenary.nvim"

nvim --headless \
	--clean \
	--noplugin \
	-c "set runtimepath+=${PLENARY_DIR}" \
	-c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = './tests/minimal_init.lua' })" \
	-c "qa!"

