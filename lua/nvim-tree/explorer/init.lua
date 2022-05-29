local uv = vim.loop

local git = require "nvim-tree.git"
local watch = require "nvim-tree.explorer.watch"

local M = {}

M.explore = require("nvim-tree.explorer.explore").explore
M.reload = require("nvim-tree.explorer.reload").reload

local Explorer = {}
Explorer.__index = Explorer

function Explorer.new(cwd)
  cwd = uv.fs_realpath(cwd or uv.cwd())
  local explorer = setmetatable({
    absolute_path = cwd,
    nodes = {},
    watcher = watch.create_watcher(cwd),
    open = true,
  }, Explorer)
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

function Explorer:_clear_watchers()
  local function iterate(node)
    if node.watcher then
      node.watcher:stop()
      for _, node_ in pairs(node.nodes) do
        if node_.watcher then
          iterate(node_)
        end
      end
    end
  end
  iterate(self)
end

function M.setup(opts)
  require("nvim-tree.explorer.explore").setup(opts)
  require("nvim-tree.explorer.filters").setup(opts)
  require("nvim-tree.explorer.sorters").setup(opts)
  require("nvim-tree.explorer.reload").setup(opts)
end

M.Explorer = Explorer

return M
