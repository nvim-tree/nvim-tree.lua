#!/bin/sh

set -e

# TODO add ability for user to specify a test file or directory

REPO_DIR="$(git rev-parse --show-toplevel)"
export REPO_DIR

PLENARY_DIR="${REPO_DIR}/plenary.nvim"
export PLENARY_DIR

nvim --headless \
	--clean \
	--noplugin \
	-u "tests/minimal_init.lua" \
	-c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = './tests/minimal_init.lua' })" \
	-c "qa!"

