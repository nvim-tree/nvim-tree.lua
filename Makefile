all: lint style check

test: functionaltest

#
# mandatory checks
#
lint: luacheck

style: style-check style-doc

check: luals

#
# subtasks
#
luacheck:
	luacheck --codes --quiet lua --exclude-files "**/_meta/**"
	luacheck --codes --quiet test

style-check:
	scripts/luals-check.sh codestyle-check lua
	scripts/luals-check.sh codestyle-check scripts
	scripts/luals-check.sh codestyle-check test

style-doc:
	scripts/doc-comments.sh

luals:
	scripts/luals-check.sh lua
	scripts/luals-check.sh scripts
	scripts/luals-check.sh test

#
# format
#
format-fix:
	CodeFormat format --config .editorconfig --workspace lua

format-check:
	CodeFormat format --config .editorconfig --workspace lua
	git diff --exit-code lua

#
# utility
#
help-update:
	scripts/vimdoc.sh doc
	scripts/help-defaults.sh

#
# CI
#
help-check: help-update
	git diff --exit-code doc/nvim-tree-lua.txt

#
# testing
#
functionaltest:
	scripts/functionaltest.sh -a

.PHONY: all lint style check luacheck style-check style-doc luals format-fix format-check help-update help-check

