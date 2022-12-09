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

function M.fn(initialisation_arg)
  local default_modifier = ":t"
  -- backwards compatibility, support modifier as boolean
  if type(initialisation_arg) == "boolean" then
    if initialisation_arg then
      modifier = ":p"
    end
  elseif type(initialisation_arg) == "string" then
    default_modifier = initialisation_arg
  end

  return function(modifier_arg)
    local node
    local modifier = default_modifier
    if type(modifier_arg) == "table" then
      node = modifier_arg
    elseif type(modifier_arg) == "string" then
      node = lib.get_node_at_cursor()
      modifier = modifier_arg
    else
      return notify.warn("Type " .. type(modifier_arg) .. " not supported in rename")
    end

    -- support for only specific modifiers have been implemented
    local allowed_modifiers = {
      ":p",
      ":t",
      ":t:r",
    }

    local lookup = {}
    for _, v in ipairs(allowed_modifiers) do
      lookup[v] = true
    end

    if lookup[modifier] == nil then
      return notify.warn(
        "Modifier " .. modifier .. " is not in allowed list : " .. table.concat(allowed_modifiers, ",")
      )
    end

    node = lib.get_last_group_node(node)
    if node.name == ".." then
      return
    end

    local namelen = node.name:len()
    local directory = node.absolute_path:sub(0, namelen - 1)
    local default_path
    local prepend = ""
    local append = ""
    if modifier == ":" then
      default_path = directory
    else
      default_path = vim.fn.fnamemodify(node.name, modifier)
      if modifier == ":t:r" then
        local extension = vim.fn.fnamemodify(node.name, ":e")
        append = extension:len() == 0 and "" or "." .. extension
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
