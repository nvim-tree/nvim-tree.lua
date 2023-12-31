local marks = require "nvim-tree.marks"
local utils = require "nvim-tree.utils"
local remove_file = require "nvim-tree.actions.fs.trash"
local notify = require "nvim-tree.notify"
local lib = require "nvim-tree.lib"

local M = {
  config = {},
}

--- Delete nodes; each removal will be optionally notified
---@param nodes Node[]
local function do_trash(nodes)
  for _, node in pairs(nodes) do
    remove_file.remove(node)
  end

  marks.clear_marks()
end

function M.bulk_trash()
  local nodes = marks.get_marks()
  if not nodes or #nodes == 0 then
    notify.warn "No bookmarks to trash."
    return
  end

  if M.config.ui.confirm.trash then
    local prompt_select = "Trash bookmarked ?"
    local prompt_input = prompt_select .. " y/N: "
    lib.prompt(prompt_input, prompt_select, { "", "y" }, { "No", "Yes" }, "nvimtree_bulk_trash", function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        do_trash(nodes)
      end
    end)
  else
    do_trash(nodes)
  end
end

function M.setup(opts)
  M.config.ui = opts.ui
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
