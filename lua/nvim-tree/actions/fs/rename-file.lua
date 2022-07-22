local uv = vim.loop

local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"

local M = {}

local function err_fmt(from, to, reason)
  return string.format("Cannot rename %s -> %s: %s", from, to, reason)
end

function M.rename(node, to)
  if utils.file_exists(to) then
    utils.notify.warn(err_fmt(node.absolute_path, to, "file already exists"))
    return
  end

  local success, err = uv.fs_rename(node.absolute_path, to)
  if not success then
    return utils.notify.warn(err_fmt(node.absolute_path, to, err))
  end
  utils.notify.info(node.absolute_path .. " ➜ " .. to)
  utils.rename_loaded_buffers(node.absolute_path, to)
  events._dispatch_node_renamed(node.absolute_path, to)
end

function M.fn(with_sub)
  return function(node)
    node = lib.get_last_group_node(node)
    if node.name == ".." then
      return
    end

    local namelen = node.name:len()
    local abs_path = with_sub and node.absolute_path:sub(0, namelen * -1 - 1) or node.absolute_path

    local input_opts = { prompt = "Rename to ", default = abs_path, completion = "file" }

    vim.ui.input(input_opts, function(new_file_path)
      utils.clear_prompt()
      if not new_file_path then
        return
      end

      M.rename(node, new_file_path)
      if M.enable_reload then
        require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
      end
    end)
  end
end

function M.setup(opts)
  M.enable_reload = not opts.filesystem_watchers.enable
end

return M
