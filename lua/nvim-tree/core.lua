local events = require "nvim-tree.events"
local explorer = require "nvim-tree.explorer"
local live_filter = require "nvim-tree.live-filter"
local view = require "nvim-tree.view"
local log = require "nvim-tree.log"
local Iterator = require "nvim-tree.iterators.node-iterator"
local utils = require "nvim-tree.utils"

local M = {}

---@type Explorer|nil
local TreeExplorer = nil
local first_init_done = false

---@param foldername string
function M.init(foldername)
  local profile = log.profile_start("core init %s", foldername)

  if TreeExplorer then
    TreeExplorer:destroy()
  end
  TreeExplorer = explorer.Explorer.new(foldername)
  if not first_init_done then
    events._dispatch_ready()
    first_init_done = true
  end
  log.profile_end(profile)
end

---@param path string
function M.change_root(path)
  if TreeExplorer == nil then
    return
  end
  local root_parent_cwd = vim.fn.fnamemodify(utils.path_remove_trailing(TreeExplorer.absolute_path), ":h")
  if root_parent_cwd == path then
    local newTreeExplorer = explorer.Explorer.new(path)
    if newTreeExplorer == nil then
      return
    end
    for _, node in ipairs(newTreeExplorer.nodes) do
      if node.absolute_path == TreeExplorer.absolute_path then
        node.nodes = TreeExplorer.nodes
      end
    end
    TreeExplorer:destroy()
    TreeExplorer = newTreeExplorer
  else
    local newTreeExplorer = explorer.Explorer.new(path)
    if newTreeExplorer == nil then
      return
    end
    local child_node
    Iterator.builder(TreeExplorer.nodes)
      :hidden()
      :applier(function(n)
        if n.absolute_path == path then
          child_node = n
        end
      end)
      :recursor(function(n)
        return n.group_next and { n.group_next } or n.nodes
      end)
      :iterate()
    if #child_node.nodes ~= 0 then
      newTreeExplorer.nodes = child_node.nodes;
    end
    TreeExplorer:destroy()
    TreeExplorer = newTreeExplorer
  end
end

---@return Explorer|nil
function M.get_explorer()
  return TreeExplorer
end

function M.reset_explorer()
  TreeExplorer = nil
end

---@return string|nil
function M.get_cwd()
  return TreeExplorer and TreeExplorer.absolute_path
end

---@return integer
function M.get_nodes_starting_line()
  local offset = 1
  if view.is_root_folder_visible(M.get_cwd()) then
    offset = offset + 1
  end
  if live_filter.filter then
    return offset + 1
  end
  return offset
end

return M
