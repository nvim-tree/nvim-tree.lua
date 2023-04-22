local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"

local M = {}

local clipboard = {
  move = {},
  copy = {},
}

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

local function do_single_paste(source, dest, action_type, action_fn)
  local dest_stats
  local success, errmsg, errcode

  log.line("copy_paste", "do_single_paste '%s' -> '%s'", source, dest)

  dest_stats, errmsg, errcode = vim.loop.fs_stat(dest)
  if not dest_stats and errcode ~= "ENOENT" then
    notify.error("Could not " .. action_type .. " " .. source .. " - " .. (errmsg or "???"))
    return false, errmsg
  end

  local function on_process()
    success, errmsg = action_fn(source, dest)
    if not success then
      notify.error("Could not " .. action_type .. " " .. source .. " - " .. (errmsg or "???"))
      return false, errmsg
    end
  end

  if dest_stats then
    local prompt_select = "Overwrite " .. dest .. " ?"
    local prompt_input = prompt_select .. " y/n/r(ename): "
    lib.prompt(prompt_input, prompt_select, { "y", "n", "r" }, { "Yes", "No", "Rename" }, function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        on_process()
      elseif item_short == "r" then
        vim.ui.input({ prompt = "Rename to ", default = dest, completion = "dir" }, function(new_dest)
          utils.clear_prompt()
          if new_dest then
            do_single_paste(source, new_dest, action_type, action_fn)
          end
        end)
      end
    end)
  else
    on_process()
  end
end

local function add_to_clipboard(node, clip)
  if node.name == ".." then
    return
  end

  for idx, _node in ipairs(clip) do
    if _node.absolute_path == node.absolute_path then
      table.remove(clip, idx)
      return notify.info(node.absolute_path .. " removed from clipboard.")
    end
  end
  table.insert(clip, node)
  notify.info(node.absolute_path .. " added to clipboard.")
end

function M.clear_clipboard()
  clipboard.move = {}
  clipboard.copy = {}
  notify.info "Clipboard has been emptied."
end

function M.copy(node)
  add_to_clipboard(node, clipboard.copy)
end

function M.cut(node)
  add_to_clipboard(node, clipboard.move)
end

local function do_paste(node, action_type, action_fn)
  node = lib.get_last_group_node(node)
  if node.name == ".." then
    node = core.get_explorer()
  end
  local clip = clipboard[action_type]
  if #clip == 0 then
    return
  end

  local destination = node.absolute_path
  local stats, errmsg, errcode = vim.loop.fs_stat(destination)
  if not stats and errcode ~= "ENOENT" then
    log.line("copy_paste", "do_paste fs_stat '%s' failed '%s'", destination, errmsg)
    notify.error("Could not " .. action_type .. " " .. destination .. " - " .. (errmsg or "???"))
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
  if M.enable_reload then
    return require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
  end
end

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

function M.paste(node)
  if clipboard.move[1] ~= nil then
    return do_paste(node, "move", do_cut)
  end

  return do_paste(node, "copy", do_copy)
end

function M.print_clipboard()
  local content = {}
  if #clipboard.move > 0 then
    table.insert(content, "Cut")
    for _, item in pairs(clipboard.move) do
      table.insert(content, " * " .. item.absolute_path)
    end
  end
  if #clipboard.copy > 0 then
    table.insert(content, "Copy")
    for _, item in pairs(clipboard.copy) do
      table.insert(content, " * " .. item.absolute_path)
    end
  end

  return notify.info(table.concat(content, "\n") .. "\n")
end

local function copy_to_clipboard(content)
  if M.use_system_clipboard == true then
    vim.fn.setreg("+", content)
    vim.fn.setreg('"', content)
    return notify.info(string.format("Copied %s to system clipboard!", content))
  else
    vim.fn.setreg('"', content)
    vim.fn.setreg("1", content)
    return notify.info(string.format("Copied %s to neovim clipboard!", content))
  end
end

function M.copy_filename(node)
  return copy_to_clipboard(node.name)
end

function M.copy_path(node)
  local absolute_path = node.absolute_path
  local relative_path = utils.path_relative(absolute_path, core.get_cwd())
  local content = node.nodes ~= nil and utils.path_add_trailing(relative_path) or relative_path
  return copy_to_clipboard(content)
end

function M.copy_absolute_path(node)
  local absolute_path = node.absolute_path
  local content = node.nodes ~= nil and utils.path_add_trailing(absolute_path) or absolute_path
  return copy_to_clipboard(content)
end

function M.setup(opts)
  M.use_system_clipboard = opts.actions.use_system_clipboard
  M.enable_reload = not opts.filesystem_watchers.enable
end

return M
