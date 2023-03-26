local keymap_legacy = require "nvim-tree.keymap-legacy"
local api = require "nvim-tree.api"
local view = require "nvim-tree.view"

local M = {}

local CMDS = {
  {
    name = "NvimTreeOpen",
    desc = "nvim-tree: open",
    opts = { nargs = "?", complete = "dir" },
    command = function(c)
      api.tree.open { path = c.args }
    end,
  },
  {
    name = "NvimTreeClose",
    desc = "nvim-tree: close",
    opts = { bar = true },
    command = function()
      api.tree.close()
    end,
  },
  {
    name = "NvimTreeToggle",
    desc = "nvim-tree: toggle",
    opts = { nargs = "?", complete = "dir" },
    command = function(c)
      api.tree.toggle { find_file = false, focus = true, path = c.args, update_root = false }
    end,
  },
  {
    name = "NvimTreeFocus",
    desc = "nvim-tree: focus",
    opts = { bar = true },
    command = function()
      api.tree.focus()
    end,
  },
  {
    name = "NvimTreeRefresh",
    desc = "nvim-tree: refresh",
    opts = { bar = true },
    command = function()
      api.tree.reload()
    end,
  },
  {
    name = "NvimTreeClipboard",
    desc = "nvim-tree: print clipboard",
    opts = { bar = true },
    command = function()
      api.fs.print_clipboard()
    end,
  },
  {
    name = "NvimTreeFindFile",
    desc = "nvim-tree: find file",
    opts = { bang = true, bar = true },
    command = function(c)
      api.tree.find_file { open = true, focus = true, update_root = c.bang }
    end,
  },
  {
    name = "NvimTreeFindFileToggle",
    desc = "nvim-tree: find file, toggle",
    opts = { bang = true, nargs = "?", complete = "dir" },
    command = function(c)
      api.tree.toggle { find_file = true, focus = true, path = c.args, update_root = c.bang }
    end,
  },
  {
    name = "NvimTreeResize",
    desc = "nvim-tree: resize",
    opts = { nargs = 1, bar = true },
    command = function(c)
      view.resize(c.args)
    end,
  },
  {
    name = "NvimTreeCollapse",
    desc = "nvim-tree: collapse",
    opts = { bar = true },
    command = function()
      api.tree.collapse_all(false)
    end,
  },
  {
    name = "NvimTreeCollapseKeepBuffers",
    desc = "nvim-tree: collapse, keep directories open",
    opts = { bar = true },
    command = function()
      api.tree.collapse_all(true)
    end,
  },
  {
    name = "NvimTreeGenerateOnAttach",
    desc = "nvim-tree: generate on_attach function from deprecated view.mappings",
    opts = {},
    command = function()
      keymap_legacy.cmd_generate_on_attach()
    end,
  },
}

function M.setup()
  for _, cmd in ipairs(CMDS) do
    local opts = vim.tbl_extend("force", cmd.opts, { desc = cmd.desc })
    vim.api.nvim_create_user_command(cmd.name, cmd.command, opts)
  end
end

return M
