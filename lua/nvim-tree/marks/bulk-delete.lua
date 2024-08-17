local utils = require "nvim-tree.utils"
local remove_file = require "nvim-tree.actions.fs.remove-file"
local notify = require "nvim-tree.notify"
local lib = require "nvim-tree.lib"

---@class BulkDelete
---@field private explorer Explorer
---@field private config table hydrated user opts.filters
local BulkDelete = {}

---@param opts table user options
---@param explorer Explorer
---@return Filters
function BulkDelete:new(opts, explorer)
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

--- Delete nodes; each removal will be optionally notified
---@param nodes Node[]
---@param marks Marks
function BulkDelete:do_delete(marks, nodes)
  for _, node in pairs(nodes) do
    remove_file.remove(node)
  end

  marks:clear_marks()

  if not self.config.filesystem_watchers.enable then
    require("nvim-tree.actions.reloaders").reload_explorer()
  end
end

--- Delete marked nodes, optionally prompting
function BulkDelete:bulk_delete()
  local marks = self.explorer.marks

  local nodes = marks:get_marks()
  if not nodes or #nodes == 0 then
    notify.warn "No bookmarksed to delete."
    return
  end

  if self.config.ui.confirm.remove then
    local prompt_select = "Remove bookmarked ?"
    local prompt_input = prompt_select .. " y/N: "
    lib.prompt(prompt_input, prompt_select, { "", "y" }, { "No", "Yes" }, "nvimtree_bulk_delete", function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        self:do_delete(marks, nodes)
      end
    end)
  else
    self:do_delete(marks, nodes)
  end
end

return BulkDelete
