vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.cmd [[set runtimepath=$VIMRUNTIME]]
vim.cmd [[set packpath=/tmp/nvt-min/site]]
local package_root = "/tmp/nvt-min/site/pack"
local install_path = package_root .. "/packer/start/packer.nvim"
local function load_plugins()
  require("packer").startup {
    {
      "wbthomason/packer.nvim",
      "nvim-tree/nvim-tree.lua",
      "nvim-tree/nvim-web-devicons",

      -- UNCOMMENT for diagnostics issues
      -- "neovim/nvim-lspconfig",

      -- ADD PLUGINS THAT ARE _NECESSARY_ FOR REPRODUCING THE ISSUE
    },
    config = {
      package_root = package_root,
      compile_path = install_path .. "/plugin/packer_compiled.lua",
      display = { non_interactive = true },
    },
  }
end
if vim.fn.isdirectory(install_path) == 0 then
  print "Installing nvim-tree and dependencies."
  vim.fn.system { "git", "clone", "--depth=1", "https://github.com/wbthomason/packer.nvim", install_path }
end
load_plugins()
require("packer").sync()
vim.cmd [[autocmd User PackerComplete ++once echo "Ready!" | lua setup()]]
vim.opt.termguicolors = true
vim.opt.cursorline = true

_G.setup = function()
  -- MODIFY NVIM-TREE SETTINGS THAT ARE _NECESSARY_ FOR REPRODUCING THE ISSUE
  require("nvim-tree").setup {
    diagnostics = {
      -- ENABLE for diagnostics issues
      enable = false,
    },
  }

  -- SETUP your language server e.g. lua-language-server, see
  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
  -- require("lspconfig").lua_ls.setup {}
end
