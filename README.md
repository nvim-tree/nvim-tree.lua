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

nnoremap <C-n> :LuaTreeToggle<CR>
nnoremap <leader>n :LuaTreeRefresh<CR>
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
- Double left click acts like `<CR>`
- Double right click acts like `.`

## Features
- [x] Open file in current buffer or in split with FzF like bindings (`<CR>`, `<C-v>`, `<C-x>`)
- [x] File icons with vim-devicons
- [x] Syntax highlighting ([exa](https://github.com/ogham/exa) like)
- [x] Change directory with `.`
- [x] Add / Rename / delete files
- [x] Git integration
- [x] Mouse support

## Screenshot

![alt text](.github/screenshot.png?raw=true "file explorer")

## TODO
- Tree creation should be async
- better error checking when fs updates
- sneak like cd command to find a directory
- better default colors (use default vim groups)
- give user option to choose for file generation command
- command to find current file in the directory structure
- create proper highlight groups or add highlight function to give the user ability to setup colors themselves
- bufferize leafs of node being closed so when opening again the node, we open every directory that was previously open
- use libuv functions instead of `touch` and `mkdir` in `create_file()` and allow file creation with path like `foo/bar/baz`
- better window management: 
  - check tree buffer/window for change so we can avoid it being resized or moved around or replaced by another file
  - monitor window layout in current tab to open files in the right place
  - add `<C-t>` to open buffer in new tab
> this might be a little hard to implement since window layout events do not exist yet
