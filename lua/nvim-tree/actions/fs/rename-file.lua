local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"

local M = {}

local ALLOWED_MODIFIERS = {
  [":p"] = true,
  [":t"] = true,
  [":t:r"] = true,
}

local function err_fmt(from, to, reason)
  return string.format("Cannot rename %s -> %s: %s", from, to, reason)
end

function M.rename(node, to)
  local success, err, delete_first

  if utils.file_exists(to) then
    local overwrite = false

    local prompt_select = "Overwrite " .. to .. " ?"
    local prompt_input = prompt_select .. " y/n: "
    lib.prompt(prompt_input, prompt_select, { "y", "n" }, { "Yes", "No" }, function(item_short)
      utils.clear_prompt()
      overwrite = item_short == "y"
    end)

    if not overwrite then
      return
    end

    -- case insensitive file systems cannot handle renaming clobbering well
    if utils.is_macos or utils.is_windows or utils.is_wsl then
      delete_first = true
    end
  end

  events._dispatch_will_rename_node(node.absolute_path, to)

  if delete_first then
    success, err = vim.loop.fs_unlink(to)
    if not success then
      return notify.warn(string.format("Cannot delete %s: %s", to, err))
    end
  end

  success, err = vim.loop.fs_rename(node.absolute_path, to)
  if not success then
    return notify.warn(err_fmt(node.absolute_path, to, err))
  end

  notify.info(node.absolute_path .. " ➜ " .. to)
  utils.rename_loaded_buffers(node.absolute_path, to)
  events._dispatch_node_renamed(node.absolute_path, to)
end

function M.fn(default_modifier)
  default_modifier = default_modifier or ":t"

  return function(node, modifier)
    if type(node) ~= "table" then
      node = lib.get_node_at_cursor()
    end

    if type(modifier) ~= "string" then
      modifier = default_modifier
    end

    -- support for only specific modifiers have been implemented
    if not ALLOWED_MODIFIERS[modifier] then
      return notify.warn(
        "Modifier " .. vim.inspect(modifier) .. " is not in allowed list : " .. table.concat(ALLOWED_MODIFIERS, ",")
      )
    end

    node = lib.get_last_group_node(node)
    if node.name == ".." then
      return
    end

    local namelen = node.name:len()
    local directory = node.absolute_path:sub(0, namelen * -1 - 1)
    local default_path
    local prepend = ""
    local append = ""
    default_path = vim.fn.fnamemodify(node.absolute_path, modifier)
    if modifier:sub(0, 2) == ":t" then
      prepend = directory
    end
    if modifier == ":t:r" then
      local extension = vim.fn.fnamemodify(node.name, ":e")
      append = extension:len() == 0 and "" or "." .. extension
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
