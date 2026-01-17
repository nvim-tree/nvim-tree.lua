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
	@scripts/luals-check.sh codestyle-check

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
	scripts/gen_vimdoc.sh

#
# CI
# --ignore-blank-lines is used as nightly has removed unnecessary blank lines that stable (0.11.5) currently inserts
#
help-check: help-update
	@scripts/lintdoc.sh
	git diff --ignore-blank-lines --exit-code doc/nvim-tree-lua.txt


.PHONY: all lint style check luacheck style-check style-doc luals style-fix help-update help-check

