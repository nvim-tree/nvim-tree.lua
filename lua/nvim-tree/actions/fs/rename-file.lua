local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"

local M = {}

local function err_fmt(from, to, reason)
  return string.format("Cannot rename %s -> %s: %s", from, to, reason)
end

function M.rename(node, to)
  if utils.file_exists(to) then
    notify.warn(err_fmt(node.absolute_path, to, "file already exists"))
    return
  end

  local success, err = vim.loop.fs_rename(node.absolute_path, to)
  if not success then
    return notify.warn(err_fmt(node.absolute_path, to, err))
  end
  notify.info(node.absolute_path .. " ➜ " .. to)
  utils.rename_loaded_buffers(node.absolute_path, to)
  events._dispatch_node_renamed(node.absolute_path, to)
end

function M.fn(with_sub, relative_rename)
  return function(node)
    node = lib.get_last_group_node(node)
    if node.name == ".." then
      return
    end

    local namelen = node.name:len()
    local abs_directory = node.absolute_path:sub(0, namelen * -1 - 1)
    local default_path, prepend, append
    if relative_rename then
      local filename = node.absolute_path:sub(abs_directory:len() + 1)
      local extension_index = filename:find("%.") or -1
      if extension_index > -1 then
        default_path = filename:sub(0, extension_index -1)
        append = filename:sub(extension_index)
      else
        default_path = filename
        append = ""
      end
      prepend = abs_directory
    else
      prepend = ""
      append = ""
      if with_sub then
        default_path = abs_directory
      else
        default_path = node.absolute_path
      end
    end

    local input_opts = { prompt = "Rename to ", default = default_path, completion = "file" }

    vim.ui.input(input_opts, function(new_file_path)
      utils.clear_prompt()
      if not new_file_path then
        return
      end

      M.rename(node, prepend .. new_file_path .. append)
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
