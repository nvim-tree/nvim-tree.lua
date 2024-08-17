local utils = require "nvim-tree.utils"
local remove_file = require "nvim-tree.actions.fs.trash"
local notify = require "nvim-tree.notify"
local lib = require "nvim-tree.lib"

---@class BulkTrash
---@field private explorer Explorer
---@field private config table hydrated user opts.filters
local BulkTrash = {}

---@param opts table user options
---@param explorer Explorer
---@return Filters
function BulkTrash:new(opts, explorer)
  local o = {
    config = {
      ui = opts.ui,
      filesystem_watchers = opts.filesystem_watchers,
    },
    explorer = explorer,
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

---Delete nodes; each removal will be optionally notified
---@private
---@param nodes Node[]
function BulkTrash:do_trash(nodes)
  for _, node in pairs(nodes) do
    remove_file.remove(node)
  end
end

function BulkTrash:bulk_trash()
  local nodes = self.explorer.marks:get_marks()
  if not nodes or #nodes == 0 then
    notify.warn "No bookmarks to trash."
    return
  end

  if self.config.ui.confirm.trash then
    local prompt_select = "Trash bookmarked ?"
    local prompt_input = prompt_select .. " y/N: "
    lib.prompt(prompt_input, prompt_select, { "", "y" }, { "No", "Yes" }, "nvimtree_bulk_trash", function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        self:do_trash(nodes)
        self.explorer.marks:clear_marks()
      end
    end)
  else
    self:do_trash(nodes)
    self.explorer.marks:clear_marks()
  end
end

return BulkTrash
