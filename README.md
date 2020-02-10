# A simple tree for neovim written in lua

## Notice

- I am working on this plugin to learn lua, learn neovim api and create a file explorer with features i need.
- I really don't like any of the vim trees, they are all too complicated for their purposes and are kind of buggy. I have my shell to do most commands.
- This plugin will not work on windows.

## TODO

- [x] moving around the file structure like any basic tree
- [x] open file in current buffer or in split with FzF like bindings (CR, C-v, C-x)
- [x] icons for files

- [x] change directory base
- [x] add / rename / delete file in directory
- [ ] update tree when altering the FS

- [ ] syntax highlighting
- [ ] simple git integration (color of file changing when staged/changed)

- [ ] quickly find file in the directory structure
- [ ] update tree automatically on window change

- [ ] handle permissions properly (TODO: display error on Read access denied)
- [ ] buffer / window should always stay on the left and never change size (open a file with only the tree open to reproduce this bug)
- [ ] buffer / window should not disappear when only the tree is opened
