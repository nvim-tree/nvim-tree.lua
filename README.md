# A simple tree for neovim written in lua

## Notice

- I am working on this plugin to learn lua, learn neovim api and create a **simple** file explorer with features i need.
- I really don't like any of the vim trees, they are all too complicated for their purposes and are kind of buggy. I have my shell to do most commands.
- This plugin does not work on windows.

## TODO

- [x] moving around the file structure like any basic tree
- [x] open file in current buffer or in split with FzF like bindings (CR, C-v, C-x)
- [ ] add / delete file in directory
- [x] icons for files
- [ ] syntax highlighting
- [ ] quickly find file in the directory structure
- [ ] simple git integration (color of file changing when staged/changed)
- [ ] update automatically on window change

## TOFIX

- [ ] handle permissions properly
- [ ] buffer / window should always stay on the left and never disappear (open a file with only the tree open to reproduce this bug)
