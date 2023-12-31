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
update-help:
	scripts/update-help.sh

.PHONY: all style lint check style-fix update-help

