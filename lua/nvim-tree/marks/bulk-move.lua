local marks = require "nvim-tree.marks"
local core = require "nvim-tree.core"
local utils = require "nvim-tree.utils"
local rename_file = require "nvim-tree.actions.fs.rename-file"
local notify = require "nvim-tree.notify"

local M = {
  config = {},
}

function M.bulk_move()
  if #marks.get_marks() == 0 then
    notify.warn "No bookmarks to move."
    return
  end

  local input_opts = {
    prompt = "Move to: ",
    default = core.get_cwd(),
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

    local nodes = marks.get_marks()
    for _, node in pairs(nodes) do
      local head = vim.fn.fnamemodify(node.absolute_path, ":t")
      local to = utils.path_join { location, head }
      rename_file.rename(node, to)
    end

    marks.clear_marks()

    if not M.config.filesystem_watchers.enable then
      require("nvim-tree.actions.reloaders").reload_explorer()
    end
  end)
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
