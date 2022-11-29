# A File Explorer For Neovim Written In Lua

[![CI](https://github.com/nvim-tree/nvim-tree.lua/actions/workflows/ci.yml/badge.svg)](https://github.com/nvim-tree/nvim-tree.lua/actions/workflows/ci.yml)

<img align="left" width="149" height="484" src="https://user-images.githubusercontent.com/17254073/195207026-f3434ba1-dc86-4c48-8ab3-b2efc3b85227.png">
<img align="left" width="149" height="484" src="https://user-images.githubusercontent.com/17254073/195207023-7b709e35-7f10-416b-aafb-5bb61268c7d3.png">

   Automatic updates

   File type icons

   Git integration

   Diagnostics integration: LSP and COC

   (Live) filtering

   Cut, copy, paste, rename, delete, create

   Highly customisable

<br clear="left"/>
<br />

Take a look at the [wiki](https://github.com/nvim-tree/nvim-tree.lua/wiki) for Showcases, Tips, Recipes and more.

[Join us on matrix](https://matrix.to/#/#nvim-tree:matrix.org)

## Requirements

[neovim >=0.7.0](https://github.com/neovim/neovim/wiki/Installing-Neovim)

[nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) is optional and used to display file icons. It requires a [patched font](https://www.nerdfonts.com/). Your terminal emulator must be configured to use that font, usually "Hack Nerd Font"

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'nvim-tree/nvim-web-devicons' " optional, for file icons
Plug 'nvim-tree/nvim-tree.lua'
```

or with [packer](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'nvim-tree/nvim-tree.lua',
  requires = {
    'nvim-tree/nvim-web-devicons', -- optional, for file icons
  },
  tag = 'nightly' -- optional, updated every week. (see issue #1193)
}
```

## Setup

Setup should be run in a lua file or in a lua heredoc [:help lua-heredoc](https://neovim.io/doc/user/lua.html) if using in a vim file.

```lua
-- examples for your init.lua

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = "u", action = "dir_up" },
      },
    },
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})
```

For complete list of available configuration options see [:help nvim-tree-setup](doc/nvim-tree-lua.txt)

Each option is documented in `:help nvim-tree.OPTION_NAME`. Nested options can be accessed by appending `.`, for example [:help nvim-tree.view.mappings](doc/nvim-tree-lua.txt)

## Commands

See [:help nvim-tree-commands](doc/nvim-tree-lua.txt)

Basic commands:

`:NvimTreeToggle` Open or close the tree. Takes an optional path argument.

`:NvimTreeFocus` Open the tree if it is closed, and then focus on the tree.

`:NvimTreeFindFile` Move the cursor in the tree for the current buffer, opening folders if needed.

`:NvimTreeCollapse` Collapses the nvim-tree recursively.

## Mappings

nvim-tree comes with number of mappings; for default mappings please see [:help nvim-tree-default-mappings](doc/nvim-tree-lua.txt), for way of configuring mappings see [:help nvim-tree-mappings](doc/nvim-tree-lua.txt)

`g?` toggles help, showing all the mappings and their actions.

## Roadmap

nvim-tree is stable and new major features will not be added. The focus is on existing user experience.

Users are encouraged to add their own custom features via the public [API](#api).

Development is focused on:
* Bug fixes
* Performance
* Quality of Life improvements
* API / Events
* Enhancements to existing features

## API

nvim-tree exposes a public API. This is non breaking, with additions made as necessary.

Please raise a [feature request](https://github.com/nvim-tree/nvim-tree.lua/issues/new?assignees=&labels=feature+request&template=feature_request.md&title=) if the API is insufficent for your needs. [Contributions](#Contributing) are always welcome.

[:help nvim-tree-api](doc/nvim-tree-lua.txt)

### Events

Users may subscribe to events that nvim-tree will dispatch in a variety of situations.

[:help nvim-tree-events](doc/nvim-tree-lua.txt)

### Actions

Custom actions may be mapped which can invoke API or perform your own actions.

[:help nvim-tree-mappings](doc/nvim-tree-lua.txt)

## Contributing

PRs are always welcome. See [wiki](https://github.com/nvim-tree/nvim-tree.lua/wiki/Development) to get started.

See [bug](https://github.com/nvim-tree/nvim-tree.lua/issues?q=is%3Aissue+is%3Aopen+label%3Abug) and [PR Please](https://github.com/nvim-tree/nvim-tree.lua/issues?q=is%3Aopen+is%3Aissue+label%3A%22PR+please%22) issues if you are looking for some work to get you started.

### Help Wanted

Developers with the following environments:

* Apple macOS
* Windows
  * WSL
  * msys
  * powershell

Help triaging, diagnosing and fixing issues specific to those environments is needed, as the nvim-tree developers do not have access to or expertise in these environments.

Let us know you're interested by commenting on issues and raising PRs.

## Screenshots

See [Showcases](https://github.com/nvim-tree/nvim-tree.lua/wiki/Showcases) wiki page for examples of user's configurations with sources.

Please add your own!

