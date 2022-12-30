local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local view = require "nvim-tree.view"
local lib = require "nvim-tree.lib"
local notify = require "nvim-tree.notify"
local async = require "nvim-tree.async"

local M = {}

local function close_windows(windows)
  if view.View.float.enable and #vim.api.nvim_list_wins() == 1 then
    return
  end

  for _, window in ipairs(windows) do
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end
end

local function clear_buffer(absolute_path)
  local bufs = vim.fn.getbufinfo { bufloaded = 1, buflisted = 1 }
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      if buf.hidden == 0 and (#bufs > 1 or view.View.float.enable) then
        local winnr = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(buf.windows[1])
        vim.cmd ":bn"
        if not view.View.float.enable then
          vim.api.nvim_set_current_win(winnr)
        end
      end
      vim.api.nvim_buf_delete(buf.bufnr, { force = true })
      if M.close_window then
        close_windows(buf.windows)
      end
      return
    end
  end
end

local function remove_dir(cwd)
  local handle = vim.loop.fs_scandir(cwd)
  if type(handle) == "string" then
    return notify.error(handle)
  end

  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local new_cwd = utils.path_join { cwd, name }
    if t == "directory" then
      local success = remove_dir(new_cwd)
      if not success then
        return false
      end
    else
      local success = vim.loop.fs_unlink(new_cwd)
      if not success then
        return false
      end
      clear_buffer(new_cwd)
    end
  end

  return vim.loop.fs_rmdir(cwd)
end

local function do_remove(node)
  if node.nodes ~= nil and not node.link_to then
    local success = remove_dir(node.absolute_path)
    if not success then
      return notify.error("Could not remove " .. node.name)
    end
    events._dispatch_folder_removed(node.absolute_path)
  else
    local success = vim.loop.fs_unlink(node.absolute_path)
    if not success then
      return notify.error("Could not remove " .. node.name)
    end
    events._dispatch_file_removed(node.absolute_path)
    clear_buffer(node.absolute_path)
  end
  notify.info(node.absolute_path .. " was properly removed.")
  if M.enable_reload then
    require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
  end
end

local function remove_dir_async(cwd)
  local handle = async.unwrap_err(async.call(function(cb)
    return vim.loop.fs_opendir(cwd, cb, 32)
  end))
  while true do
    local _, entries = async.call(vim.loop.fs_readdir, handle)
    if not entries or #entries == 0 then
      break
    end
    local tasks = {}
    for _, entry in pairs(entries or {}) do
      async.schedule()
      local name = entry.name
      local t = entry.type
      local new_cwd = utils.path_join { cwd, name }
      if t == "directory" then
        remove_dir_async(new_cwd)
      else
        table.insert(tasks, function()
          async.unwrap_err(async.call(vim.loop.fs_unlink, new_cwd))
          async.schedule()
          clear_buffer(new_cwd)
        end)
      end
    end
    async.all(unpack(tasks))
  end

  async.unwrap_err(async.call(vim.loop.fs_rmdir, cwd))
end

local function do_remove_async(node)
  async.exec(function()
    if node.nodes ~= nil and not node.link_to then
      remove_dir_async(node.absolute_path)
      async.schedule()
      events._dispatch_folder_removed(node.absolute_path)
    else
      async.unwrap_err(async.call(vim.loop.fs_unlink, node.absolute_path))
      async.schedule()
      events._dispatch_file_removed(node.absolute_path)
      clear_buffer(node.absolute_path)
    end
  end, function(err)
    if err then
      notify.error("Could not remove " .. node.name .. ": " .. tostring(err))
    else
      notify.info(node.absolute_path .. " was properly removed.")
      if M.enable_reload then
        require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
      end
    end
  end)
end

function M.fn(node)
  if node.name == ".." then
    return
  end
  local prompt_select = "Remove " .. node.name .. " ?"
  local prompt_input = prompt_select .. " y/n: "
  lib.prompt(prompt_input, prompt_select, { "y", "n" }, { "Yes", "No" }, function(item_short)
    utils.clear_prompt()
    if item_short == "y" then
      if M.enable_async then
        do_remove_async(node)
      else
        do_remove(node)
      end
    end
  end)
end

function M.setup(opts)
  M.enable_reload = not opts.filesystem_watchers.enable
  M.close_window = opts.actions.remove_file.close_window
  M.enable_async = opts.experimental.async.remove_file
end

return M
