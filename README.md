# A File Explorer For Neovim Written In Lua

![alt text](.github/tree.png?raw=true "screenshot")

## Notice

- I am working on this plugin to learn lua, learn neovim api and create a file explorer with features i need.
- I really don't like any of the vim trees, they are all too complicated for their purposes and are kind of buggy. I have my shell to do most commands.
- This plugin will not work on windows.

## Features
- [x] Open file in current buffer or in split with FzF like bindings (`CR`, `C-v`, `C-x`)
- [x] File icons with vim-devicons
- [x] Syntax highlighting ([exa](https://github.com/ogham/exa) like)
- [x] Change directory with `C-[`
- [x] Add / Rename / delete files
- [x] Git integration
- [x] Mouse support

## TODO
- [ ] handle colorscheme better (right now its based on random global variables that might not be loaded at vim start)

- [ ] handle permissions properly (TODO: display error on Read access denied)
- [ ] buffer / window should not disappear when only the tree is opened
- [ ] buffer / window should always stay on the left and never change size (open a file with only the tree open to reproduce this bug)

- [ ] handle symbolic links
- [ ] quickly find file in the directory structure
- [ ] update tree automatically on window change
