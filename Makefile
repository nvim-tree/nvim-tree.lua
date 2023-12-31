all: lint style check

#
# mandatory checks
#
lint:
	luacheck -q lua
	scripts/doc-comments.sh

style:
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
help-check:
	scripts/help-update.sh
	git diff --exit-code doc/nvim-tree-lua.txt

.PHONY: all style lint check style-fix help-check help-update

