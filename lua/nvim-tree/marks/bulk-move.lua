local core = require "nvim-tree.core"
local utils = require "nvim-tree.utils"
local rename_file = require "nvim-tree.actions.fs.rename-file"
local notify = require "nvim-tree.notify"
local lib = require "nvim-tree.lib"

---@class BulkMove
---@field private explorer Explorer
---@field private config table hydrated user opts.filters
local BulkMove = {}

---@param opts table user options
---@param explorer Explorer
---@return Filters
function BulkMove:new(opts, explorer)
  local o = {
    config = {
      filesystem_watchers = opts.filesystem_watchers,
    },
    explorer = explorer,
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

function BulkMove:bulk_move()
  local marks = self.explorer.marks

  if #marks:get_marks() == 0 then
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

    local nodes = marks:get_marks()
    for _, node in pairs(nodes) do
      local head = vim.fn.fnamemodify(node.absolute_path, ":t")
      local to = utils.path_join { location, head }
      rename_file.rename(node, to)
    end

    marks:clear_marks()

    if not self.config.filesystem_watchers.enable then
      require("nvim-tree.actions.reloaders").reload_explorer()
    end
  end)
end

return BulkMove
