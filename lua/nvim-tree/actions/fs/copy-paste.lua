local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"
local renderer = require "nvim-tree.renderer"
local reloaders = require "nvim-tree.actions.reloaders"

local find_file = require("nvim-tree.actions.finders.find-file").fn

local M = {
  config = {},
}

local clipboard = {
  cut = {},
  copy = {},
}

---@param source string
---@param destination string
---@return boolean
---@return string|nil
local function do_copy(source, destination)
  local source_stats, handle
  local success, errmsg

  source_stats, errmsg = vim.loop.fs_stat(source)
  if not source_stats then
    log.line("copy_paste", "do_copy fs_stat '%s' failed '%s'", source, errmsg)
    return false, errmsg
  end

  log.line("copy_paste", "do_copy %s '%s' -> '%s'", source_stats.type, source, destination)

  if source == destination then
    log.line("copy_paste", "do_copy source and destination are the same, exiting early")
    return true
  end

  if source_stats.type == "file" then
    success, errmsg = vim.loop.fs_copyfile(source, destination)
    if not success then
      log.line("copy_paste", "do_copy fs_copyfile failed '%s'", errmsg)
      return false, errmsg
    end
    return true
  elseif source_stats.type == "directory" then
    handle, errmsg = vim.loop.fs_scandir(source)
    if type(handle) == "string" then
      return false, handle
    elseif not handle then
      log.line("copy_paste", "do_copy fs_scandir '%s' failed '%s'", source, errmsg)
      return false, errmsg
    end

    success, errmsg = vim.loop.fs_mkdir(destination, source_stats.mode)
    if not success then
      log.line("copy_paste", "do_copy fs_mkdir '%s' failed '%s'", destination, errmsg)
      return false, errmsg
    end

    while true do
      local name, _ = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      local new_name = utils.path_join { source, name }
      local new_destination = utils.path_join { destination, name }
      success, errmsg = do_copy(new_name, new_destination)
      if not success then
        return false, errmsg
      end
    end
  else
    errmsg = string.format("'%s' illegal file type '%s'", source, source_stats.type)
    log.line("copy_paste", "do_copy %s", errmsg)
    return false, errmsg
  end

  return true
end

---@param source string
---@param dest string
---@param action_type string
---@param action_fn fun(source: string, dest: string)
---@return boolean|nil -- success
---@return string|nil -- error message
local function do_single_paste(source, dest, action_type, action_fn)
  local dest_stats
  local success, errmsg, errcode
  local notify_source = notify.render_path(source)

  log.line("copy_paste", "do_single_paste '%s' -> '%s'", source, dest)

  dest_stats, errmsg, errcode = vim.loop.fs_stat(dest)
  if not dest_stats and errcode ~= "ENOENT" then
    notify.error("Could not " .. action_type .. " " .. notify_source .. " - " .. (errmsg or "???"))
    return false, errmsg
  end

  local function on_process()
    success, errmsg = action_fn(source, dest)
    if not success then
      notify.error("Could not " .. action_type .. " " .. notify_source .. " - " .. (errmsg or "???"))
      return false, errmsg
    end

    find_file(utils.path_remove_trailing(dest))
  end

  if dest_stats then
    local input_opts = {
      prompt = "Rename to ",
      default = dest,
      completion = "dir",
    }

    if source == dest then
      vim.ui.input(input_opts, function(new_dest)
        utils.clear_prompt()
        if new_dest then
          do_single_paste(source, new_dest, action_type, action_fn)
        end
      end)
    else
      local prompt_select = "Overwrite " .. dest .. " ?"
      local prompt_input = prompt_select .. " R(ename)/y/n: "
      lib.prompt(prompt_input, prompt_select, { "", "y", "n" }, { "Rename", "Yes", "No" }, "nvimtree_overwrite_rename", function(item_short)
        utils.clear_prompt()
        if item_short == "y" then
          on_process()
        elseif item_short == "" or item_short == "r" then
          vim.ui.input(input_opts, function(new_dest)
            utils.clear_prompt()
            if new_dest then
              do_single_paste(source, new_dest, action_type, action_fn)
            end
          end)
        end
      end)
    end
  else
    on_process()
  end
end

---@param node Node
---@param clip table
local function toggle(node, clip)
  if node.name == ".." then
    return
  end
  local notify_node = notify.render_path(node.absolute_path)

  if utils.array_remove(clip, node) then
    notify.info(notify_node .. " removed from clipboard.")
    return
  end

  table.insert(clip, node)
  notify.info(notify_node .. " added to clipboard.")
end

function M.clear_clipboard()
  clipboard.cut = {}
  clipboard.copy = {}
  notify.info "Clipboard has been emptied."
  renderer.draw()
end

---@param node Node
function M.copy(node)
  utils.array_remove(clipboard.cut, node)
  toggle(node, clipboard.copy)
  renderer.draw()
end

---@param node Node
function M.cut(node)
  utils.array_remove(clipboard.copy, node)
  toggle(node, clipboard.cut)
  renderer.draw()
end

---@param node Node
---@param action_type string
---@param action_fn fun(source: string, dest: string)
local function do_paste(node, action_type, action_fn)
  node = lib.get_last_group_node(node)
  local explorer = core.get_explorer()
  if node.name == ".." and explorer then
    node = explorer
  end
  local clip = clipboard[action_type]
  if #clip == 0 then
    return
  end

  local destination = node.absolute_path
  local stats, errmsg, errcode = vim.loop.fs_stat(destination)
  if not stats and errcode ~= "ENOENT" then
    log.line("copy_paste", "do_paste fs_stat '%s' failed '%s'", destination, errmsg)
    notify.error("Could not " .. action_type .. " " .. notify.render_path(destination) .. " - " .. (errmsg or "???"))
    return
  end
  local is_dir = stats and stats.type == "directory"
  if not is_dir then
    destination = vim.fn.fnamemodify(destination, ":p:h")
  end

  for _, _node in ipairs(clip) do
    local dest = utils.path_join { destination, _node.name }
    do_single_paste(_node.absolute_path, dest, action_type, action_fn)
  end

  clipboard[action_type] = {}
  if not M.config.filesystem_watchers.enable then
    reloaders.reload_explorer()
  end
end

---@param source string
---@param destination string
---@return boolean
---@return string?
local function do_cut(source, destination)
  log.line("copy_paste", "do_cut '%s' -> '%s'", source, destination)

  if source == destination then
    log.line("copy_paste", "do_cut source and destination are the same, exiting early")
    return true
  end

  events._dispatch_will_rename_node(source, destination)
  local success, errmsg = vim.loop.fs_rename(source, destination)
  if not success then
    log.line("copy_paste", "do_cut fs_rename failed '%s'", errmsg)
    return false, errmsg
  end
  utils.rename_loaded_buffers(source, destination)
  events._dispatch_node_renamed(source, destination)
  return true
end

---@param node Node
function M.paste(node)
  if clipboard.cut[1] ~= nil then
    do_paste(node, "cut", do_cut)
  else
    do_paste(node, "copy", do_copy)
  end
end

function M.print_clipboard()
  local content = {}
  if #clipboard.cut > 0 then
    table.insert(content, "Cut")
    for _, node in pairs(clipboard.cut) do
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end
  if #clipboard.copy > 0 then
    table.insert(content, "Copy")
    for _, node in pairs(clipboard.copy) do
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end

  notify.info(table.concat(content, "\n") .. "\n")
end

---@param content string
local function copy_to_clipboard(content)
  local clipboard_name
  if M.config.actions.use_system_clipboard == true then
    vim.fn.setreg("+", content)
    vim.fn.setreg('"', content)
    clipboard_name = "system"
  else
    vim.fn.setreg('"', content)
    vim.fn.setreg("1", content)
    clipboard_name = "neovim"
  end

  vim.api.nvim_exec_autocmds("TextYankPost", {})
  notify.info(string.format("Copied %s to %s clipboard!", content, clipboard_name))
end

---@param node Node
function M.copy_filename(node)
  copy_to_clipboard(node.name)
end

---@param node Node
function M.copy_path(node)
  local absolute_path = node.absolute_path
  local cwd = core.get_cwd()
  if cwd == nil then
    return
  end

  local relative_path = utils.path_relative(absolute_path, cwd)
  local content = node.nodes ~= nil and utils.path_add_trailing(relative_path) or relative_path
  copy_to_clipboard(content)
end

---@param node Node
function M.copy_absolute_path(node)
  local absolute_path = node.absolute_path
  local content = node.nodes ~= nil and utils.path_add_trailing(absolute_path) or absolute_path
  copy_to_clipboard(content)
end

---Node is cut. Will not be copied.
---@param node Node
---@return boolean
function M.is_cut(node)
  return vim.tbl_contains(clipboard.cut, node)
end

---Node is copied. Will not be cut.
---@param node Node
---@return boolean
function M.is_copied(node)
  return vim.tbl_contains(clipboard.copy, node)
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
  M.config.actions = opts.actions
end

return M
