# A File Explorer For Neovim Written In Lua

[![CI](https://github.com/nvim-tree/nvim-tree.lua/actions/workflows/ci.yml/badge.svg)](https://github.com/nvim-tree/nvim-tree.lua/actions/workflows/ci.yml)

<img align="left" width="199" height="598" src="https://user-images.githubusercontent.com/1505378/232662694-8dc494e0-24da-497a-8541-29344293378c.png">
<img align="left" width="199" height="598" src="https://user-images.githubusercontent.com/1505378/232662698-2f321315-c67a-486b-85d8-8c391de52392.png">

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

Questions and general support: [Discussions](https://github.com/nvim-tree/nvim-tree.lua/discussions)

## Requirements

[neovim >=0.9.0](https://github.com/neovim/neovim/wiki/Installing-Neovim)

[nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) is optional and used to display file icons. It requires a [patched font](https://www.nerdfonts.com/). Your terminal emulator must be configured to use that font, usually "Hack Nerd Font"

## Install

Please install via your preferred package manager. See [Installation](https://github.com/nvim-tree/nvim-tree.lua/wiki/Installation) for specific package manager instructions.

`nvim-tree/nvim-tree.lua`

Major or minor versions may be specified via tags: `v<MAJOR>` e.g. `v1` or `v<MAJOR>.<MINOR>` e.g. `v1.23`

`nvim-tree/nvim-web-devicons` optional, for file icons

Disabling [netrw](https://neovim.io/doc/user/pi_netrw.html) is strongly advised, see [:help nvim-tree-netrw](doc/nvim-tree-lua.txt)

## Quick Start

### Setup

Setup the plugin in your `init.lua`

```lua
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})
```

### Help

Open the tree:  `:NvimTreeOpen`

Show the mappings:  `g?`

### Custom Mappings

[:help nvim-tree-mappings-default](doc/nvim-tree-lua.txt) are applied by default however you may customise via |nvim-tree.on_attach| e.g.

```lua
local function my_on_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- default mappings
  api.map.on_attach.default(bufnr)

  -- custom mappings
  vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent,        opts('Up'))
  vim.keymap.set('n', '?',     api.tree.toggle_help,                  opts('Help'))
end

-- pass to setup along with your other options
require("nvim-tree").setup {
  ---
  on_attach = my_on_attach,
  ---
}
```

### Highlight

Run `:NvimTreeHiTest` to show all the highlights that nvim-tree uses.

They can be customised before or after setup is called and will be immediately
applied at runtime. e.g.

```lua
vim.cmd([[
    :hi      NvimTreeExecFile    guifg=#ffa0a0
    :hi      NvimTreeSpecialFile guifg=#ff80ff gui=underline
    :hi      NvimTreeSymlink     guifg=Yellow  gui=italic
    :hi link NvimTreeImageFile   Title
]])
```
See [:help nvim-tree-highlight](doc/nvim-tree-lua.txt) for details.

## Commands

See [:help nvim-tree-commands](doc/nvim-tree-lua.txt)

Basic commands:

`:NvimTreeToggle` Open or close the tree. Takes an optional path argument.

`:NvimTreeFocus` Open the tree if it is closed, and then focus on the tree.

`:NvimTreeFindFile` Move the cursor in the tree for the current buffer, opening folders if needed.

`:NvimTreeCollapse` Collapses the nvim-tree recursively.

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

nvim-tree exposes a public API. This is non breaking, with additions made as necessary. See [:help nvim-tree-api](doc/nvim-tree-lua.txt)

See wiki [Recipes](https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes) and [Tips](https://github.com/nvim-tree/nvim-tree.lua/wiki/Tips) for ideas and inspiration.

Please raise a [feature request](https://github.com/nvim-tree/nvim-tree.lua/issues/new?assignees=&labels=feature+request&template=feature_request.md&title=) if the API is insufficient for your needs. Contributions are always welcome, see below.

You may also subscribe to events that nvim-tree will dispatch in a variety of situations, see [:help nvim-tree-events](doc/nvim-tree-lua.txt)

## Contributing

PRs are always welcome. See [CONTRIBUTING](CONTRIBUTING.md) and [wiki: Development](https://github.com/nvim-tree/nvim-tree.lua/wiki/Development) to get started.

See [bug](https://github.com/nvim-tree/nvim-tree.lua/issues?q=is%3Aissue+is%3Aopen+label%3Abug) and [PR Please](https://github.com/nvim-tree/nvim-tree.lua/issues?q=is%3Aopen+is%3Aissue+label%3A%22PR+please%22) issues if you are looking for some work to get you started.

## Screenshots

See [Showcases](https://github.com/nvim-tree/nvim-tree.lua/wiki/Showcases) wiki page for examples of user's configurations with sources.

Please add your own!

## Team

* [@alex-courtis](https://github.com/alex-courtis) Arch Linux
* [@gegoune](https://github.com/gegoune) macOS
* [@Akmadan23](https://github.com/Akmadan23) Linux
* [@dependabot[bot]](https://github.com/apps/dependabot) Ubuntu Linux
