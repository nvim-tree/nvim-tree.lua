all: lint style check

#
# mandatory checks
#
lint: luacheck

style: stylua style-doc

check: luals

#
# subtasks
#
luacheck:
	luacheck -q lua

stylua:
	stylua lua --check

style-doc:
	scripts/doc-comments.sh

luals:
	scripts/luals-check.sh

#
# fixes
#
style-fix:
	stylua lua

#
# utility
#
help-update:
	scripts/help-update.sh

#
# CI
#
help-check: help-update
	git diff --exit-code doc/nvim-tree-lua.txt


.PHONY: all lint style check luacheck stylua style-doc luals style-fix help-update help-check

