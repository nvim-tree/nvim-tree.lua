local git = require "nvim-tree.git"
local notify = require "nvim-tree.notify"
local watch = require "nvim-tree.explorer.watch"
local explorer_node = require "nvim-tree.explorer.node"

local Filters = require "nvim-tree.explorer.filters"
local Marks = {} -- circular dependencies
local LiveFilter = require "nvim-tree.explorer.live-filter"
local Sorters = require "nvim-tree.explorer.sorters"
local Clipboard = {} -- circular dependencies

local config

---@class Explorer
---@field absolute_path string
---@field nodes Node[]
---@field open boolean
---@field filters Filters
---@field live_filter LiveFilter
---@field sorters Sorter
---@field marks Marks
---@field clipboard Clipboard
local Explorer = {}

Explorer.explore = require("nvim-tree.explorer.explore").explore
Explorer.reload = require("nvim-tree.explorer.reload").reload

---@param path string|nil
---@return Explorer|nil
function Explorer:new(path)
  local err

  if path then
    path, err = vim.loop.fs_realpath(path)
  else
    path, err = vim.loop.cwd()
  end
  if not path then
    notify.error(err)
    return
  end

  ---@class Explorer
  local o = setmetatable({
    absolute_path = path,
    nodes = {},
    open = true,
    sorters = Sorters:new(config),
  }, Explorer)
  setmetatable(o, self)
  self.__index = self

  o.watcher = watch.create_watcher(o)
  o.filters = Filters:new(config, o)
  o.live_filter = LiveFilter:new(config, o)
  o.marks = Marks:new(config, o)
  o.clipboard = Clipboard:new(config, o)

  o:_load(o)

  return o
end

---@private
---@param node Node
function Explorer:_load(node)
  local cwd = node.link_to or node.absolute_path
  local git_status = git.load_project_status(cwd)
  Explorer.explore(node, git_status, self)
end

---@param node Node
function Explorer:expand(node)
  self:_load(node)
end

function Explorer:destroy()
  local function iterate(node)
    explorer_node.node_destroy(node)
    if node.nodes then
      for _, child in pairs(node.nodes) do
        iterate(child)
      end
    end
  end
  iterate(self)
end

function Explorer.setup(opts)
  config = opts
  require("nvim-tree.explorer.node").setup(opts)
  require("nvim-tree.explorer.explore").setup(opts)
  require("nvim-tree.explorer.reload").setup(opts)
  require("nvim-tree.explorer.watch").setup(opts)

  Marks = require "nvim-tree.marks"
  Clipboard = require "nvim-tree.actions.fs.clipboard"
end

return Explorer
