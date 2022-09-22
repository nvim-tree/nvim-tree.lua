# A File Explorer For Neovim Written In Lua

[![CI](https://github.com/kyazdani42/nvim-tree.lua/actions/workflows/ci.yml/badge.svg)](https://github.com/kyazdani42/nvim-tree.lua/actions/workflows/ci.yml)

<img align="left" width="124" height="332" src=".github/example.png?raw=true">

   Automatic updates

   File type icons

   Git integration

   Diagnostics integration: LSP and COC

   (Live) filtering

   Cut, copy, paste, rename, delete, create

   Highly customisable

<br clear="left"/>
<br />

[Join us on matrix](https://matrix.to/#/#nvim-tree:matrix.org)

## Requirements

[neovim >=0.7.0](https://github.com/neovim/neovim/wiki/Installing-Neovim)

[nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons) is optional and used to display file icons. It requires a [patched font](https://www.nerdfonts.com/).

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'kyazdani42/nvim-web-devicons' " optional, for file icons
Plug 'kyazdani42/nvim-tree.lua'
```

or with [packer](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'kyazdani42/nvim-tree.lua',
  requires = {
    'kyazdani42/nvim-web-devicons', -- optional, for file icons
  },
  tag = 'nightly' -- optional, updated every week. (see issue #1193)
}
```

## Setup

Setup should be run in a lua file or in a lua heredoc [:help lua-heredoc](https://neovim.io/doc/user/lua.html) if using in a vim file.

```lua
-- examples for your init.lua

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

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

## Api

nvim-tree exposes a public api; see [:help nvim-tree-api](doc/nvim-tree-lua.txt). This is a stable non breaking api.

## Mappings

nvim-tree comes with number of mappings; for default mappings please see [:help nvim-tree-default-mappings](doc/nvim-tree-lua.txt), for way of configuring mappings see [:help nvim-tree-mappings](doc/nvim-tree-lua.txt)

`g?` toggles help, showing all the mappings and their actions.

## Tips & tricks

* You can add a directory by adding a `/` at the end of the paths, entering multiple directories `BASE/foo/bar/baz` will add directory foo, then bar and add a file baz to it.
* You can update window options for the tree by setting `require"nvim-tree.view".View.winopts.MY_OPTION = MY_OPTION_VALUE`
* `toggle` has a second parameter which allows to toggle without focusing the explorer (`require"nvim-tree".toggle(false, true)`).
* You can allow nvim-tree to behave like vinegar, see [:help nvim-tree-vinegar](doc/nvim-tree-lua.txt)
* If you `:set nosplitright`, the files will open on the left side of the tree, placing the tree window in the right side of the file you opened.
* You can automatically close the tab/vim when nvim-tree is the last window in the tab: <https://github.com/kyazdani42/nvim-tree.lua/discussions/1115>. WARNING: this can catastrophically fail: <https://github.com/kyazdani42/nvim-tree.lua/issues/1368>. This will not be added to nvim-tree and the team will not provide support / assistance with this, due to complexities in vim event timings and side-effects.
* Hide the `.git` folder: `filters = { custom = { "^.git$" } }`. See [:help nvim-tree.filters.custom](doc/nvim-tree-lua.txt).
* To disable the display of icons see [:help nvim-tree.renderer.icons.show](doc/nvim-tree-lua.txt).

## Troubleshooting

## Diagnostic Logging

You may enable diagnostic logging to `$XDG_CACHE_HOME/nvim/nvim-tree.log`. See [:help nvim-tree.log](doc/nvim-tree-lua.txt)

## netrw Keeps Popping Up

Eagerly disable netrw. See [:help nvim-tree.disable_netrw](doc/nvim-tree-lua.txt)

## Performance Issues

If you are experiencing performance issues with nvim-tree.lua, you can enable profiling in the logs. It is advisable to enable git logging at the same time, as that can be a source of performance problems.

```lua
log = {
  enable = true,
  truncate = true,
  types = {
    git = true,
    profile = true,
  },
},
```

Please attach `$XDG_CACHE_HOME/nvim/nvim-tree.log` if you raise an issue.

*Performance Tips:*

* If you are using fish as an editor shell (which might be fixed in the future), try set `shell=/bin/bash` in your vim config. Alternatively, you can [prevent fish from loading interactive configuration in a non-interactive shell](https://github.com/kyazdani42/nvim-tree.lua/issues/549#issuecomment-1127394585).

* Try manually running the git command (see the logs) in your shell e.g. `git --no-optional-locks status --porcelain=v1 --ignored=matching -u`.

* Huge git repositories may timeout after the default `git.timeout` of 400ms. Try increasing that in your setup if you see `[git] job timed out` in the logs.

* Try temporarily disabling git integration by setting `git.enable = false` in your setup.

## Contributing

PRs are always welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)

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

![alt text](.github/screenshot.png?raw=true "kyazdani42 tree")
![alt text](.github/screenshot2.png?raw=true "akin909 tree")
![alt text](.github/screenshot3.png?raw=true "stsewd tree")
![alt text](.github/screenshot4.png?raw=true "reyhankaplan tree")
