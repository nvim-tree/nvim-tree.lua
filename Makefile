all: lint style check

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

# --diagnosis-as-error does not function for workspace, hence we post-process the output
style-check:
	CodeFormat check --config .editorconfig --diagnosis-as-error --workspace lua

style-doc:
	scripts/doc-comments.sh

luals:
	@scripts/luals-check.sh

#
# fixes
#
style-fix:
	CodeFormat format --config .editorconfig --workspace lua

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


.PHONY: all lint style check luacheck style-check style-doc luals style-fix help-update help-check

