#!/usr/bin/env sh

# run after changing default config or keymap.lua M.on_attach_default
# scrapes and updates nvim-tree-lua.txt
# run from repository root: scripts/help-defaults.sh  OR  make help-update

set -e

#
# Operate on a temporary file as sed -i writes the file thousands of times.
#
WIP="/tmp/nvim-tree-lua.txt"
cp "doc/nvim-tree-lua.txt" "${WIP}"


#
# Inject default config
#
begin="config-default-start"
end="config-default-end"
inject="config-default-injection-placeholder"

# scrape config.default, indented at 2
sed -n -E "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/config.lua > /tmp/config.default.2.lua

# indent to match help
sed -E "s/^  /      /" /tmp/config.default.2.lua > /tmp/config.default.6.lua

# inject then remove the placeholder
sed -i -E "/${inject}/r /tmp/DEFAULT_OPTS.6.lua" "${WIP}"
sed -i -E "/${inject}/d" "${WIP}"

#
# Inject default mappings
#

begin="BEGIN_ON_ATTACH_DEFAULT"
end="END_ON_ATTACH_DEFAULT"

# scrape ON_ATTACH_DEFAULT, indented at 2
sed -n -E "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/keymap.lua > /tmp/ON_ATTACH_DEFAULT.lua

# help lua
sed -i -E "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/ON_ATTACH_DEFAULT.lua
           }; /${end}/p; d; }" "${WIP}"

# help human
echo > /tmp/ON_ATTACH_DEFAULT.help
sed -E "s/^ *vim.keymap.set\(\"n\", \"(.*)\",.*api(.*),.*opts\(\"(.*)\".*$/'\`\1\`' '\3' '|nvim_tree.api\2()|'/g
" /tmp/ON_ATTACH_DEFAULT.lua | while read -r line
do
	eval "printf '%-17.17s %-26.26s %s\n' ${line}" >> /tmp/ON_ATTACH_DEFAULT.help
done
echo >> /tmp/ON_ATTACH_DEFAULT.help
begin="Show the mappings:"
end="======"
sed -i -E "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/ON_ATTACH_DEFAULT.help
           }; /${end}/p; d; }" "${WIP}"

#
# complete
#
mv "${WIP}" "doc/nvim-tree-lua.txt"
