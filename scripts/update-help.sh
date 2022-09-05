#!/bin/sh

# run after changing nvim-tree.lua DEFAULT_OPTS or nvim-tree/actions/init.lua M.mappings
# scrapes and updates nvim-tree-lua.txt
# run from repository root: scripts/update-default-opts.sh


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
# DEFAULT_KEYMAPS
#

begin="BEGIN_DEFAULT_KEYMAPS"
end="END_DEFAULT_KEYMAPS"

# scrape DEFAULT_KEYMAPS
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; s/callback = \(.*\),/callback = '\1',/g; p; }" lua/nvim-tree/keymap.lua > /tmp/DEFAULT_KEYMAPS.M.lua

# generate /tmp/DEFAULT_KEYMAPS.on_attach.lua, /tmp/DEFAULT_KEYMAPS.help and /tmp/LEGACY_CALLBACKS.lua
cat /tmp/DEFAULT_KEYMAPS.M.lua scripts/generate_default_keymaps.lua | lua

# legacy.lua LEGACY_CALLBACKS
begin="BEGIN_LEGACY_CALLBACKS"
end="END_LEGACY_CALLBACKS"
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/LEGACY_CALLBACKS.lua
           }; /${end}/p; d }" lua/nvim-tree/legacy.lua

# help on_attach
begin="BEGIN_ON_ATTACH"
end="END_ON_ATTACH"
sed -i -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_KEYMAPS.on_attach.lua
           }; /${end}/p; d }" doc/nvim-tree-lua.txt

# help human
sed -i -e "/^DEFAULT MAPPINGS/,/^>$/{ /^DEFAULT MAPPINGS/{p; r /tmp/DEFAULT_KEYMAPS.help
           }; /^>$/p; d }" doc/nvim-tree-lua.txt

