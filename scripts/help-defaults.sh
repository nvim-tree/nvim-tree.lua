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
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/config.lua > /tmp/config.default.2.lua

# indent to match help
sed -e "s/^  /      /" /tmp/config.default.2.lua > /tmp/config.default.6.lua

# inject then remove the placeholder
sed -i -e "/${inject}/r /tmp/config.default.6.lua" -e "/${inject}/d" "${WIP}"

#
# Inject default mappings
#

begin="BEGIN_ON_ATTACH_DEFAULT"
end="END_ON_ATTACH_DEFAULT"

# scrape ON_ATTACH_DEFAULT, indented at 2
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/keymap.lua > /tmp/ON_ATTACH_DEFAULT.lua

# help lua
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/ON_ATTACH_DEFAULT.lua
           }; /${end}/p; d; }" "${WIP}"

# help human
# extract mode, lhs, api, desc; handle both "n" and {"n", "x"} mode forms
echo > /tmp/ON_ATTACH_DEFAULT.help
sed -E '
  s/^ *vim\.keymap\.set\(\{([^}]+)\}, *"([^"]+)",.*api(.*),.*opts\("([^"]*)".*/\1 \2 \3 \4/
  t reformat
  s/^ *vim\.keymap\.set\("(.)", *"([^"]+)",.*api(.*),.*opts\("([^"]*)".*/\1 \2 \3 \4/
  t reformat
  d
  :reformat
  s/"//g
  s/, //g
' /tmp/ON_ATTACH_DEFAULT.lua | while read -r mode lhs apipath desc
do
  printf ' %-17.17s %-4.4s %-26.26s %s\n' "\`${lhs}\`" "${mode}" "${desc}" "|nvim_tree.api${apipath}()|" >> /tmp/ON_ATTACH_DEFAULT.help
done
echo >> /tmp/ON_ATTACH_DEFAULT.help
begin="Show the mappings:"
end="======"
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/ON_ATTACH_DEFAULT.help
           }; /${end}/p; d; }" "${WIP}"

#
# complete
#
mv "${WIP}" "doc/nvim-tree-lua.txt"
