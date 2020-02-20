# A File Explorer For Neovim Written In Lua

![alt text](.github/tree.png?raw=true "file explorer")

## Notice

- I am working on this plugin to learn lua, neovim's api and create a file explorer with features i need.
- This plugin does not work on windows.

## Features
- [x] Open file in current buffer or in split with FzF like bindings (`CR`, `C-v`, `C-x`)
- [x] File icons with vim-devicons
- [x] Syntax highlighting ([exa](https://github.com/ogham/exa) like)
- [x] Change directory with `C-[`
- [x] Add / Rename / delete files
- [x] Git integration
- [x] Mouse support

## TODO
- add docs
- fix coloring when no dev icons
- add options for users (tree side, tree size)
- cd command to move faster accross the fs if needed
- quickly find file in the directory structure
- use libuv functions instead of `touch` and `mkdir` in `create_file()` and allow file creation with path like `foo/bar/baz`
- tree should always stay on the left no matter what

