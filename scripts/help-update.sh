#!/bin/sh

# run after changing nvim-tree.lua DEFAULT_OPTS or keymap.lua M.default_on_attach
# scrapes and updates nvim-tree-lua.txt
# run from repository root: scripts/help-update.sh  OR  make help-update


#
# DEFAULT_OPTS
#
begin="BEGIN_DEFAULT_OPTS"
end="END_DEFAULT_OPTS"

# scrape DEFAULT_OPTS, indented at 2
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree.lua > /tmp/DEFAULT_OPTS.2.lua

# indent some more
sed -e "s/^  /      /" /tmp/DEFAULT_OPTS.2.lua > /tmp/DEFAULT_OPTS.6.lua

# help, indented at 6
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_OPTS.6.lua
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt


#
# opts index
#
begin="nvim-tree-index-opts\*"
end="====================="

printf '\n' > /tmp/index-opts.txt
sed -E "
/^ *\*(nvim-tree\..*)\*$/! d ;
s/^.*\*(.*)\*/|\1|/g
" doc/nvim-tree-lua.txt | sort -d >> /tmp/index-opts.txt
printf '\n' >> /tmp/index-opts.txt

sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/index-opts.txt
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt

#
# api index
#
begin="nvim-tree-index-api\*"
end="====================="

printf '\n' > /tmp/index-api.txt
sed -E "
/\*(nvim-tree-api.*\(\))\*/! d ;
s/^.*\*(.*)\*/|\1|/g
" doc/nvim-tree-lua.txt | sort -d >> /tmp/index-api.txt
printf '\n' >> /tmp/index-api.txt

sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/index-api.txt
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt

#
# DEFAULT_ON_ATTACH
#

begin="BEGIN_DEFAULT_ON_ATTACH"
end="END_DEFAULT_ON_ATTACH"

# scrape DEFAULT_ON_ATTACH, indented at 2
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/keymap.lua > /tmp/DEFAULT_ON_ATTACH.lua

# help lua
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_ON_ATTACH.lua
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt

# help human
echo > /tmp/DEFAULT_ON_ATTACH.help
sed -E "s/^ *vim.keymap.set\(\"n\", \"(.*)\",.*api(.*),.*opts\(\"(.*)\".*$/'\`\1\`' '\3' '|nvim-tree-api\2()|'/g
" /tmp/DEFAULT_ON_ATTACH.lua | while read -r line
do
	eval "printf '%-17.17s %-26.26s %s\n' ${line}" >> /tmp/DEFAULT_ON_ATTACH.help
done
echo >> /tmp/DEFAULT_ON_ATTACH.help
begin="Show the mappings:"
end="======"
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_ON_ATTACH.help
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt
