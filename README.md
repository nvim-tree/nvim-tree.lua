# A File Explorer For Neovim Written In Lua

## Notice

- I am working on this plugin to learn lua, neovim's api and create a file explorer with features i need.
- This plugin does not work on windows.

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'kyazdani42/nvim-tree.lua'
```

## Setup

```vim
let g:lua_tree_side = 'right' | 'left' "left by default
let g:lua_tree_size = 40 "30 by default
let g:lua_tree_ignore = [ '.git', 'node_modules', '.cache' ] "empty by default, not working on mac atm
let g:lua_tree_auto_open = 1 "0 by default, opens the tree when typing `vim $DIR` or `vim`
let g:lua_tree_auto_close = 1 "0 by default, closes the tree when it's the last window
let g:lua_tree_follow = 1 "0 by default, this option will bind BufEnter to the LuaTreeFindFile command
" :help LuaTreeFindFile for more info

nnoremap <C-n> :LuaTreeToggle<CR>
nnoremap <leader>r :LuaTreeRefresh<CR>
nnoremap <leader>n :LuaTreeFindFile<CR>
```

## KeyBindings

- move around like in any vim buffer
- `<CR>` on `..` will cd in the above directory
- `.` will cd in the directory under the cursor
- type `a` to add a file
- type `r` to rename a file
- type `d` to delete a file (will prompt for confirmation)
- if the file is a directory, `<CR>` will open the directory
- otherwise it will open the file in the buffer near the tree
- if the file is a symlink, `<CR>` will follow the symlink
- type `<C-v>` will open the file in a vertical split
- type `<C-x>` will open the file in a horizontal split
- type `<C-t>` will open the file in a new tab
- Double left click acts like `<CR>`
- Double right click acts like `.`

## Features
- [x] Open file in current buffer or in split with FzF like bindings (`<CR>`, `<C-v>`, `<C-x>`, `<C-t>`)
- [x] File icons with vim-devicons
- [x] Syntax highlighting ([exa](https://github.com/ogham/exa) like)
- [x] Change directory with `.`
- [x] Add / Rename / delete files
- [x] Git integration
- [x] Mouse support

## Screenshot

![alt text](.github/screenshot.png?raw=true "file explorer")

## TODO

### Perf / Fixes
- Tree creation should be async
- refactor all `system` call to `libuv` functions, with better error management
- bufferize leafs of node being closed so when opening again the node, we open every directory that was previously open
- make config module to make it easier to add/modify user options

### Features
- sneak like cd command to find a file/directory
- better default colors (use default vim groups)
- create proper highlight groups or add highlight function to give the user ability to setup colors themselves

### Window Feature / Fixes
- opening help should open on the bottom
- better window management: 
  - check tree buffer/window for change so we can avoid it being resized or moved around or replaced by another file
  - monitor window layout in current tab to open files in the right place
> this might be a little hard to implement since window layout events do not exist yet

