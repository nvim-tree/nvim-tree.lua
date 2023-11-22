local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"
local utils_ui = require "nvim-tree.utils-ui"

local find_file = require("nvim-tree.actions.finders.find-file").fn

local M = {
  config = {},
}

local function err_fmt(from, to, reason)
  return string.format("Cannot rename %s -> %s: %s", from, to, reason)
end

--- note: this function is used elsewhere
--- @param node table
--- @param path string path destination
function M.rename_node_to(node, path)
  local notify_from = notify.render_path(node.absolute_path)
  local notify_to = notify.render_path(path)

  if utils.file_exists(path) then
    notify.warn(err_fmt(notify_from, notify_to, "file already exists"))
    return
  end

  events._dispatch_will_rename_node(node.absolute_path, path)
  local success, err = vim.loop.fs_rename(node.absolute_path, path)
  if not success then
    return notify.warn(err_fmt(notify_from, notify_to, err))
  end
  notify.info(string.format("%s -> %s", notify_from, notify_to))
  utils.rename_loaded_buffers(node.absolute_path, path)
  events._dispatch_node_renamed(node.absolute_path, path)
end

--- @class fsPromptForRenameOpts: InputPathEditorOpts

--- @param opts? fsPromptForRenameOpts
function M.prompt_for_rename(node, opts)
  if type(node) ~= "table" then
    node = lib.get_node_at_cursor()
  end

  local opts_default = { absolute = true }
  if type(opts) ~= "table" then
    opts = opts_default
  end

  node = lib.get_last_group_node(node)
  if node.name == ".." then
    return
  end

  local default_path = utils_ui.Input_path_editor:new(node.absolute_path, opts)

  local input_opts = {
    prompt = "Rename to ",
    default = default_path:prepare(),
    completion = "file",
  }

  vim.ui.input(input_opts, function(new_file_path)
    utils.clear_prompt()
    if not new_file_path then
      return
    end

    M.rename_node_to(node, default_path:restore(new_file_path))
    if not M.config.filesystem_watchers.enable then
      require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
    end

    find_file(utils.path_remove_trailing(new_file_path))
  end)
end -- M.prompt_for_rename

function M.rename_basename(node)
  return M.prompt_for_rename(node, { basename = true })
end
function M.rename_absolute(node)
  return M.prompt_for_rename(node, { absolute = true })
end
function M.rename(node)
  return M.prompt_for_rename(node, { filename = true })
end
function M.rename_sub(node)
  return M.prompt_for_rename(node, { dirname = true })
end
function M.rename_relative(node)
  return M.prompt_for_rename(node, { relative = true })
end

--- @deprecated
M.fn = function()
  -- Warn if used in plugins directly
  error("nvim-tree: method is deprecated, use rename_* instead; see nvim-tree.lua/lua/nvim-tree/actions/fs/rename-file.lua", 2)
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
