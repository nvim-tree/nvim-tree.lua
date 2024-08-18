local core = {} -- circular dependency
local lib = {} -- circular dependency
local notify = require "nvim-tree.notify"
local remove_file = {} -- circular dependency
local rename_file = {} -- circular dependency
local trash = {} -- circular dependency
local renderer = {} -- circular dependency
local utils = require "nvim-tree.utils"

---@class Marks
---@field config table hydrated user opts.filters
---@field private explorer Explorer
---@field private marks table<string, Node> by absolute path
local Marks = {}

---@return Marks
---@param opts table user options
---@param explorer Explorer
function Marks:new(opts, explorer)
  local o = {
    explorer = explorer,
    config = {
      ui = opts.ui,
      filesystem_watchers = opts.filesystem_watchers,
    },
    marks = {},
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

---Clear all marks and reload if watchers disabled
---@private
function Marks:clear_reload()
  self:clear()
  if not self.config.filesystem_watchers.enable then
    require("nvim-tree.actions.reloaders").reload_explorer()
  end
end

---Clear all marks and redraw
---@public
function Marks:clear()
  self.marks = {}
  renderer.draw()
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

  renderer.draw()
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
function Marks:delete()
  if not next(self.marks) then
    notify.warn "No bookmarks to delete."
    return
  end

  local function execute()
    for _, node in pairs(self.marks) do
      remove_file.remove(node)
    end
    self:clear_reload()
  end

  if self.config.ui.confirm.remove then
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
function Marks:trash()
  if not next(self.marks) then
    notify.warn "No bookmarks to trash."
    return
  end

  local function execute()
    for _, node in pairs(self.marks) do
      trash.remove(node)
    end
    self:clear_reload()
  end

  if self.config.ui.confirm.trash then
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
function Marks:move()
  if not next(self.marks) then
    notify.warn "No bookmarks to move."
    return
  end

  local node_at_cursor = lib.get_node_at_cursor()
  local default_path = core.get_cwd()

  if node_at_cursor and node_at_cursor.type == "directory" then
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
      local to = utils.path_join { location, head }
      rename_file.rename(node, to)
    end

    self:clear_reload()
  end)
end

function Marks.setup()
  core = require "nvim-tree.core"
  lib = require "nvim-tree.lib"
  remove_file = require "nvim-tree.actions.fs.remove-file"
  rename_file = require "nvim-tree.actions.fs.rename-file"
  renderer = require "nvim-tree.renderer"
  trash = require "nvim-tree.actions.fs.trash"
end

return Marks
