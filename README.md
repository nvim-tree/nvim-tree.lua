# A File Explorer For Neovim Written In Lua

## Notice

This plugin doesn't support windows. \
This plugin requires [neovim nightly](https://github.com/neovim/neovim/wiki/Installing-Neovim). \
You can switch to commit `afc86a9` if you use neovim 0.4.x. \
Note that the old version has less features and is much slower than the new one.

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
" master (neovim git)
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'

" old version that runs on neovim 0.4.x
Plug 'kyazdani42/nvim-tree.lua' { 'commit': 'afc86a9' }
" for icons in old version
Plug 'ryanoasis/vim-devicons'
```

## Setup

```vim
let g:lua_tree_side = 'right' | 'left' "left by default
let g:lua_tree_size = 40 "30 by default
let g:lua_tree_ignore = [ '.git', 'node_modules', '.cache' ] "empty by default
let g:lua_tree_auto_open = 1 "0 by default, opens the tree when typing `vim $DIR` or `vim`
let g:lua_tree_auto_close = 1 "0 by default, closes the tree when it's the last window
let g:lua_tree_follow = 1 "0 by default, this option allows the cursor to be updated when entering a buffer
let g:lua_tree_show_icons = {
    \ 'git': 1,
    \ 'folders': 0,
    \ 'files': 0,
    \}
"If 0, do not show the icons for one of 'git' 'folder' and 'files'
"1 by default, notice that if 'files' is 1, it will only display
"if nvim-web-devicons is installed and on your runtimepath

" You can edit keybindings be defining this variable
" You don't have to define all keys.
" NOTE: the 'edit' key will wrap/unwrap a folder and open a file
let g:lua_tree_bindings = {
    \ 'edit':        '<CR>',
    \ 'edit_vsplit': '<C-v>',
    \ 'edit_split':  '<C-x>',
    \ 'edit_tab':    '<C-t>',
    \ 'cd':          '.',
    \ 'create':      'a',
    \ 'remove':      'd',
    \ 'rename':      'r'
    \ }

" default will show icon by default if no icon is provided
" default shows no icon by default
let g:lua_tree_icons = {
    \ 'default': '',
    \ 'git': {
    \   'unstaged': "✗",
    \   'staged': "✓",
    \   'unmerged': "═",
    \   'renamed': "➜",
    \   'untracked': "★"
    \   }
    \ }

nnoremap <C-n> :LuaTreeToggle<CR>
nnoremap <leader>r :LuaTreeRefresh<CR>
nnoremap <leader>n :LuaTreeFindFile<CR>
" LuaTreeOpen and LuaTreeClose are also available if you need them

set termguicolors " this variable must be enabled for colors to be applied properly

" a list of groups can be found at `:help lua_tree_highlight`
highlight LuaTreeFolderIcon guibg=blue
```

## KeyBindings

- move around like in any vim buffer
- `<CR>` on `..` will cd in the above directory
- `.` will cd in the directory under the cursor
- type `a` to add a file. Adding a directory requires leaving a leading `/` at the end of the path.
> you can add multiple directories by doing foo/bar/baz/f and it will add foo bar and baz directories and f as a file
- type `r` to rename a file
- type `d` to delete a file (will prompt for confirmation)
- if the file is a directory, `<CR>` will open the directory otherwise it will open the file in the buffer near the tree
- if the file is a symlink, `<CR>` will follow the symlink (if the target is a file)
- type `<C-v>` will open the file in a vertical split
- type `<C-x>` will open the file in a horizontal split
- type `<C-t>` will open the file in a new tab
- type `gx` to open the file with the `open` command on MACOS and `xdg-open` in linux
- Double left click acts like `<CR>`
- Double right click acts like `.`

## Note

This plugin is very fast because it uses the `libuv` `scandir` and `scandir_next` functions instead of spawning an `ls` process which can get slow on large files when combining with `stat` to get file informations.

## Features
- Open file in current buffer or in split with FzF like bindings (`<CR>`, `<C-v>`, `<C-x>`, `<C-t>`)
- File icons with nvim-web-devicons
- Syntax highlighting ([exa](https://github.com/ogham/exa) like)
- Change directory with `.`
- Add / Rename / delete files
- Git integration
- Mouse support
- It's fast

## Screenshot

![alt text](.github/screenshot.png?raw=true "file explorer")
