#!/bin/sh

# run after changing nvim-tree.lua DEFAULT_OPTS or nvim-tree/actions/init.lua M.mappings
# scrapes and updates nvim-tree-lua.txt
# run from repositry root: scripts/update-default-opts.sh


begin="BEGIN_DEFAULT_OPTS"
end="END_DEFAULT_OPTS"

# scrape DEFAULT_OPTS, indented at 2
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree.lua > /tmp/DEFAULT_OPTS.2.lua

# indent some more
sed -e "s/^  /      /" /tmp/DEFAULT_OPTS.2.lua > /tmp/DEFAULT_OPTS.6.lua

# help, indented at 6
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_OPTS.6.lua
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt


begin="BEGIN_DEFAULT_MAPPINGS"
end="END_DEFAULT_MAPPINGS"

# generate various DEFAULT_MAPPINGS
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/actions/init.lua > /tmp/DEFAULT_MAPPINGS.M.lua
cat /tmp/DEFAULT_MAPPINGS.M.lua scripts/generate_default_mappings.lua | lua

# help
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_MAPPINGS.lua
           }; /${end}/p; d }" doc/nvim-tree-lua.txt
sed -i -e "/^DEFAULT MAPPINGS/,/^>$/{ /^DEFAULT MAPPINGS/{p; r /tmp/DEFAULT_MAPPINGS.help
           }; /^>$/p; d }" doc/nvim-tree-lua.txt
