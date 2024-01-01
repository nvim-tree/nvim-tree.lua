all: lint style check

#
# mandatory checks
#
lint:
	luacheck -q lua

style: style-doc
	stylua lua --check

check:
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

style-doc:
	scripts/doc-comments.sh

.PHONY: all style lint check style-fix help-check help-update style-doc

