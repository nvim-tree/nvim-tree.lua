local git = require "nvim-tree.git"
local watch = require "nvim-tree.explorer.watch"
local common = require "nvim-tree.explorer.common"

local M = {}

M.explore = require("nvim-tree.explorer.explore").explore
M.reload = require("nvim-tree.explorer.reload").reload

local Explorer = {}
Explorer.__index = Explorer

function Explorer.new(cwd)
  cwd = vim.loop.fs_realpath(cwd or vim.loop.cwd())
  local explorer = setmetatable({
    absolute_path = cwd,
    nodes = {},
    open = true,
  }, Explorer)
  explorer.watcher = watch.create_watcher(explorer)
  explorer:_load(explorer)
  return explorer
end

function Explorer:_load(node)
  local cwd = node.link_to or node.absolute_path
  local git_statuses = git.load_project_status(cwd)
  M.explore(node, git_statuses)
end

function Explorer:expand(node)
  self:_load(node)
end

function Explorer:destroy()
  local function iterate(node)
    common.node_destroy(node)
    if node.nodes then
      for _, child in pairs(node.nodes) do
        iterate(child)
      end
    end
  end
  iterate(self)
end

function M.setup(opts)
  require("nvim-tree.explorer.common").setup(opts)
  require("nvim-tree.explorer.explore").setup(opts)
  require("nvim-tree.explorer.filters").setup(opts)
  require("nvim-tree.explorer.sorters").setup(opts)
  require("nvim-tree.explorer.reload").setup(opts)
  require("nvim-tree.explorer.watch").setup(opts)
end

M.Explorer = Explorer

return M
