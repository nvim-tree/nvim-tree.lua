#!/bin/sh

# run after changing nvim-tree.lua DEFAULT_OPTS or keymap.lua M.default_on_attach
# scrapes and updates nvim-tree-lua.txt and keymap-legacy.lua
# run from repository root: scripts/update-help.sh


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
# DEFAULT_ON_ATTACH
#

begin="BEGIN_DEFAULT_ON_ATTACH"
end="END_DEFAULT_ON_ATTACH"

# scrape DEFAULT_ON_ATTACH, indented at 2
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree/keymap.lua > /tmp/DEFAULT_ON_ATTACH.lua

# help
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_ON_ATTACH.lua
           }; /${end}/p; d; }" doc/nvim-tree-lua.txt

# legacy keymap
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_ON_ATTACH.lua
           }; /${end}/p; d; }" lua/nvim-tree/keymap-legacy.lua

