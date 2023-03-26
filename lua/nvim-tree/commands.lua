local keymap_legacy = require "nvim-tree.keymap-legacy"
local api = require "nvim-tree.api"
local view = require "nvim-tree.view"

local M = {}

local CMDS = {
  {
    name = "NvimTreeOpen",
    opts = {
      desc = "nvim-tree: open",
      nargs = "?",
      complete = "dir",
    },
    command = function(c)
      api.tree.open { path = c.args }
    end,
  },
  {
    name = "NvimTreeClose",
    opts = {
      desc = "nvim-tree: close",
      bar = true,
    },
    command = function()
      api.tree.close()
    end,
  },
  {
    name = "NvimTreeToggle",
    opts = {
      desc = "nvim-tree: toggle",
      nargs = "?",
      complete = "dir",
    },
    command = function(c)
      api.tree.toggle { find_file = false, focus = true, path = c.args, update_root = false }
    end,
  },
  {
    name = "NvimTreeFocus",
    opts = {
      desc = "nvim-tree: focus",
      bar = true,
    },
    command = function()
      api.tree.focus()
    end,
  },
  {
    name = "NvimTreeRefresh",
    opts = {
      desc = "nvim-tree: refresh",
      bar = true,
    },
    command = function()
      api.tree.reload()
    end,
  },
  {
    name = "NvimTreeClipboard",
    opts = {
      desc = "nvim-tree: print clipboard",
      bar = true,
    },
    command = function()
      api.fs.print_clipboard()
    end,
  },
  {
    name = "NvimTreeFindFile",
    opts = {
      desc = "nvim-tree: find file",
      bang = true,
      bar = true,
    },
    command = function(c)
      api.tree.find_file { open = true, focus = true, update_root = c.bang }
    end,
  },
  {
    name = "NvimTreeFindFileToggle",
    opts = {
      desc = "nvim-tree: find file, toggle",
      bang = true,
      nargs = "?",
      complete = "dir",
    },
    command = function(c)
      api.tree.toggle { find_file = true, focus = true, path = c.args, update_root = c.bang }
    end,
  },
  {
    name = "NvimTreeResize",
    opts = {
      desc = "nvim-tree: resize",
      nargs = 1,
      bar = true,
    },
    command = function(c)
      view.resize(c.args)
    end,
  },
  {
    name = "NvimTreeCollapse",
    opts = {
      desc = "nvim-tree: collapse",
      bar = true,
    },
    command = function()
      api.tree.collapse_all(false)
    end,
  },
  {
    name = "NvimTreeCollapseKeepBuffers",
    opts = {
      desc = "nvim-tree: collapse, keep directories open",
      bar = true,
    },
    command = function()
      api.tree.collapse_all(true)
    end,
  },
  {
    name = "NvimTreeGenerateOnAttach",
    opts = {
      desc = "nvim-tree: generate on_attach function from deprecated view.mappings",
    },
    command = function()
      keymap_legacy.cmd_generate_on_attach()
    end,
  },
}

function M.get()
  return vim.deepcopy(CMDS)
end

function M.setup()
  for _, cmd in ipairs(CMDS) do
    local opts = vim.tbl_extend("force", cmd.opts, { force = true })
    vim.api.nvim_create_user_command(cmd.name, cmd.command, opts)
  end
end

return M
