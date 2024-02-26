local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"

local find_file = require("nvim-tree.actions.finders.find-file").fn

local M = {
  config = {},
}

---@param iter function iterable
---@return integer
local function get_num_nodes(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

local ALLOWED_MODIFIERS = {
  [":p"] = true,
  [":p:h"] = true,
  [":t"] = true,
  [":t:r"] = true,
}

local function err_fmt(from, to, reason)
  return string.format("Cannot rename %s -> %s: %s", from, to, reason)
end

---@param node Node
---@param to string
function M.rename(node, to)
  local notify_from = notify.render_path(node.absolute_path)
  local notify_to = notify.render_path(to)

  if utils.file_exists(to) then
    notify.warn(err_fmt(notify_from, notify_to, "file already exists"))
    return
  end

  -- create a folder for each path element if the folder does not exist
  local idx = 0
  local path_to_create = ""

  local num_nodes = get_num_nodes(utils.path_split(utils.path_remove_trailing(to)))
  local is_error = false
  for path in utils.path_split(to) do
    idx = idx + 1

    local p = utils.path_remove_trailing(path)
    if #path_to_create == 0 and vim.fn.has "win32" == 1 then
      path_to_create = utils.path_join { p, path_to_create }
    else
      path_to_create = utils.path_join { path_to_create, p }
    end

    if idx == num_nodes then
      events._dispatch_will_rename_node(node.absolute_path, to)
      local success, err = vim.loop.fs_rename(node.absolute_path, to)

      if not success then
        notify.warn(err_fmt(notify_from, notify_to, err))
        return
      end
    elseif not utils.file_exists(path_to_create) then
      local success = vim.loop.fs_mkdir(path_to_create, 493)
      if not success then
        notify.error("Could not create folder " .. notify.render_path(path_to_create))
        is_error = true
        break
      end
      is_error = false
    end
  end

  if not is_error then
    notify.info(string.format("%s -> %s", notify_from, notify_to))
    utils.rename_loaded_buffers(node.absolute_path, to)
    events._dispatch_node_renamed(node.absolute_path, to)
  end
end

---@param default_modifier string|nil
---@return fun(node: Node, modifier: string)
function M.fn(default_modifier)
  default_modifier = default_modifier or ":t"

  return function(node, modifier)
    if type(node) ~= "table" then
      node = lib.get_node_at_cursor()
    end

    if node == nil then
      return
    end

    if type(modifier) ~= "string" then
      modifier = default_modifier
    end

    -- support for only specific modifiers have been implemented
    if not ALLOWED_MODIFIERS[modifier] then
      notify.warn("Modifier " .. vim.inspect(modifier) .. " is not in allowed list : " .. table.concat(ALLOWED_MODIFIERS, ","))
      return
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
    if modifier == ":p:h" then
      default_path = default_path .. "/"
    end

    local input_opts = {
      prompt = "Rename to ",
      default = default_path,
      completion = "file",
    }

    vim.ui.input(input_opts, function(new_file_path)
      utils.clear_prompt()
      if not new_file_path then
        return
      end

      M.rename(node, prepend .. new_file_path .. append)
      if not M.config.filesystem_watchers.enable then
        require("nvim-tree.actions.reloaders").reload_explorer()
      end

      find_file(utils.path_remove_trailing(new_file_path))
    end)
  end
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
