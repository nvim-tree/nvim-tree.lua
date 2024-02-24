#!/bin/sh

# run after adding api entry
# paste into nvim-tree-index-api
# manual fixing may be required

sed -E "
/\*(nvim-tree-api.*)\*/! d ;
s/.*\*(nvim-tree-api[^\(\)]*)\*.*/\n|\1|/g
s/.*\*(nvim-tree-api.*\(\))\*.*/|\1|/g
" doc/nvim-tree-lua.txt

