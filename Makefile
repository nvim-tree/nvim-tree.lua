all: lint style check

#
# mandatory checks
#
lint: luacheck

style: style-check style-check-test style-doc

check: luals-check luals-check-test

#
# subtasks
#
luacheck:
	luacheck --codes --quiet lua --exclude-files "**/_meta/**"
	luacheck --codes --quiet test

style-check:
	scripts/luals-check.sh codestyle-check lua
	scripts/luals-check.sh codestyle-check scripts

style-check-test:
	scripts/luals-check.sh codestyle-check test

style-doc:
	scripts/doc-comments.sh

luals-check:
	scripts/luals-check.sh lua
	scripts/luals-check.sh scripts

luals-check-test:
	scripts/luals-check.sh test

#
# format
#
format-fix:
	CodeFormat format --config .editorconfig --workspace lua
	CodeFormat format --config .editorconfig --workspace test

format-check:
	CodeFormat format --config .editorconfig --workspace lua
	git diff --exit-code lua
	CodeFormat format --config .editorconfig --workspace test
	git diff --exit-code test

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

.PHONY: all lint style check luacheck style-check style-check-test style-doc luals-check luals-check-test format-fix format-check help-update help-check

