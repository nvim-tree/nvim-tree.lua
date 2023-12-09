local Iterator = require "nvim-tree.iterators.node-iterator"
local core = require "nvim-tree.core"
local Marks = require "nvim-tree.marks"
local open_file = require "nvim-tree.actions.node.open-file"
local utils = require "nvim-tree.utils"
local lib = require "nvim-tree.lib"

---@param node table
---@param where string
---@return Node|nil
local function get_nearest(node, where)
  local first, prev, next, last = nil, nil, nil, nil
  local found = false

  Iterator.builder(core.get_explorer().nodes)
    :recursor(function(n)
      return n.open and n.nodes
    end)
    :applier(function(n)
      if n.absolute_path == node.absolute_path then
        found = true
        return
      end

      if not Marks.get_mark(n) then
        return
      end

      last = n
      first = first or n

      if found and not next then
        next = n
      end

      if not found then
        prev = n
      end
    end)
    :iterate()

  if not found then
    return
  end

  if where == "next" then
    return next or first
  else
    return prev or last
  end
end

---@param where string
---@param node table|nil
---@return Node|nil
local function get(where, node)
  if node then
    return get_nearest(node, where)
  end
end

---@param node table|nil
local function open_or_focus(node)
  if node and not node.nodes and not utils.get_win_buf_from_path(node.absolute_path) then
    open_file.fn("edit", node.absolute_path)
  elseif node then
    utils.focus_file(node.absolute_path)
  end
end

---@param where string
---@return function
local function navigate_to(where)
  return function()
    local node = lib.get_node_at_cursor()
    local next = get(where, node)
    open_or_focus(next)
  end
end

local M = {}

M.next = navigate_to "next"
M.prev = navigate_to "prev"

function M.select()
  local list = vim.tbl_map(function(n)
    return n.absolute_path
  end, Marks.get_marks())

  vim.ui.select(list, {
    prompt = "Select a file to open or a folder to focus",
  }, function(choice)
    if not choice or choice == "" then
      return
    end
    local node = Marks.get_mark { absolute_path = choice }
    open_or_focus(node)
  end)
end

return M
