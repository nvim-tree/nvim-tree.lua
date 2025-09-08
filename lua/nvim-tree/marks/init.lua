local Iterator = require("nvim-tree.iterators.node-iterator")
local core = require("nvim-tree.core")
local lib = require("nvim-tree.lib")
local notify = require("nvim-tree.notify")
local open_file = require("nvim-tree.actions.node.open-file")
local remove_file = require("nvim-tree.actions.fs.remove-file")
local rename_file = require("nvim-tree.actions.fs.rename-file")
local trash = require("nvim-tree.actions.fs.trash")
local utils = require("nvim-tree.utils")

local Class = require("nvim-tree.classic")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) Marks: Class
---@field private explorer Explorer
---@field private marks table<string, Node> by absolute path
local Marks = Class:extend()

---@class Marks
---@overload fun(args: MarksArgs): Marks

---@class (exact) MarksArgs
---@field explorer Explorer

---@protected
---@param args MarksArgs
function Marks:new(args)
  self.explorer = args.explorer

  self.marks = {}
end

---Clear all marks and reload if watchers disabled
---@private
function Marks:clear_reload()
  self:clear()
  if not self.explorer.opts.filesystem_watchers.enable then
    self.explorer:reload_explorer()
  end
end

---Clear all marks and redraw
---@public
function Marks:clear()
  self.marks = {}
  self.explorer.renderer:draw()
end

---@public
---@param node Node
function Marks:toggle(node)
  if node.absolute_path == nil then
    return
  end

  if self:get(node) then
    self.marks[node.absolute_path] = nil
  else
    self.marks[node.absolute_path] = node
  end

  self.explorer.renderer:draw()
end

---Return node if marked
---@public
---@param node Node
---@return Node|nil
function Marks:get(node)
  return node and self.marks[node.absolute_path]
end

---List marked nodes
---@public
---@return Node[]
function Marks:list()
  local list = {}
  for _, node in pairs(self.marks) do
    table.insert(list, node)
  end
  return list
end

---Delete marked; each removal will be optionally notified
---@public
function Marks:bulk_delete()
  if not next(self.marks) then
    notify.warn("No bookmarks to delete.")
    return
  end

  local function execute()
    for _, node in pairs(self.marks) do
      remove_file.remove(node)
    end
    self:clear_reload()
  end

  if self.explorer.opts.ui.confirm.remove then
    local prompt_select = "Remove bookmarked ?"
    local prompt_input = prompt_select .. " y/N: "
    lib.prompt(prompt_input, prompt_select, { "", "y" }, { "No", "Yes" }, "nvimtree_bulk_delete", function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        execute()
      end
    end)
  else
    execute()
  end
end

---Trash marked; each removal will be optionally notified
---@public
function Marks:bulk_trash()
  if not next(self.marks) then
    notify.warn("No bookmarks to trash.")
    return
  end

  local function execute()
    for _, node in pairs(self.marks) do
      trash.remove(node)
    end
    self:clear_reload()
  end

  if self.explorer.opts.ui.confirm.trash then
    local prompt_select = "Trash bookmarked ?"
    local prompt_input = prompt_select .. " y/N: "
    lib.prompt(prompt_input, prompt_select, { "", "y" }, { "No", "Yes" }, "nvimtree_bulk_trash", function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        execute()
      end
    end)
  else
    execute()
  end
end

---Move marked
---@public
function Marks:bulk_move()
  if not next(self.marks) then
    notify.warn("No bookmarks to move.")
    return
  end

  local node_at_cursor = self.explorer:get_node_at_cursor()
  local default_path = core.get_cwd()

  if node_at_cursor and node_at_cursor:is(DirectoryNode) then
    default_path = node_at_cursor.absolute_path
  elseif node_at_cursor and node_at_cursor.parent then
    default_path = node_at_cursor.parent.absolute_path
  end

  local input_opts = {
    prompt = "Move to: ",
    default = default_path,
    completion = "dir",
  }

  vim.ui.input(input_opts, function(location)
    utils.clear_prompt()
    if not location or location == "" then
      return
    end
    if vim.fn.filewritable(location) ~= 2 then
      notify.warn(location .. " is not writable, cannot move.")
      return
    end

    for _, node in pairs(self.marks) do
      local head = vim.fn.fnamemodify(node.absolute_path, ":t")
      local to = utils.path_join({ location, head })
      rename_file.rename(node, to)
    end

    self:clear_reload()
  end)
end

---Focus nearest marked node in direction.
---@private
---@param up boolean
function Marks:navigate(up)
  local node = self.explorer:get_node_at_cursor()
  if not node then
    return
  end

  local first, prev, next, last = nil, nil, nil, nil
  local found = false

  Iterator.builder(self.explorer.nodes)
    :recursor(function(n)
      local dir = n:as(DirectoryNode)
      return dir and dir.open and dir.nodes
    end)
    :applier(function(n)
      if n.absolute_path == node.absolute_path then
        found = true
        return
      end

      if not self:get(n) then
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

  if up then
    utils.focus_node_or_parent(prev or last)
  else
    utils.focus_node_or_parent(next or first)
  end
end

---@public
function Marks:navigate_prev()
  self:navigate(true)
end

---@public
function Marks:navigate_next()
  self:navigate(false)
end

---Prompts for selection of a marked node, sorted by absolute paths.
---A folder will be focused, a file will be opened.
---@public
function Marks:navigate_select()
  local list = vim.tbl_map(function(n)
    return n.absolute_path
  end, self:list())

  table.sort(list)

  vim.ui.select(list, {
    prompt = "Select a file to open or a folder to focus",
  }, function(choice)
    if not choice or choice == "" then
      return
    end
    local node = self.marks[choice]
    if node and not node:is(DirectoryNode) and not utils.get_win_buf_from_path(node.absolute_path) then
      open_file.fn("edit", node.absolute_path)
    elseif node then
      self.explorer:focus_file(node.absolute_path)
    end
  end)
end

return Marks
