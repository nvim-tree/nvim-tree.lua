local Marks = require "nvim-tree.marks"
local Core = require "nvim-tree.core"
local utils = require "nvim-tree.utils"
local FsRename = require "nvim-tree.actions.fs.rename-file"
local notify = require "nvim-tree.notify"

local M = {
  config = {},
}

function M.bulk_move()
  if #Marks.get_marks() == 0 then
    notify.warn "no bookmark to perform bulk move on, aborting."
    return
  end

  vim.ui.input({ prompt = "Move to: ", default = Core.get_cwd(), completion = "dir" }, function(location)
    utils.clear_prompt()
    if not location or location == "" then
      return
    end
    if vim.fn.filewritable(location) ~= 2 then
      notify.warn(location .. " is not writable, cannot move.")
      return
    end

    local marks = Marks.get_marks()
    for _, node in pairs(marks) do
      local head = vim.fn.fnamemodify(node.absolute_path, ":t")
      local to = utils.path_join { location, head }
      FsRename.rename(node, to)
    end

    if not M.config.filesystem_watchers.enable then
      require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
    end
  end)
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
