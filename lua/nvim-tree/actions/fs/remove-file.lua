local a = vim.api
local luv = vim.loop

local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local view = require "nvim-tree.view"
local lib = require "nvim-tree.lib"

local M = {}

local function close_windows(windows)
  if view.View.float.enable and #a.nvim_list_wins() == 1 then
    return
  end

  for _, window in ipairs(windows) do
    if a.nvim_win_is_valid(window) then
      a.nvim_win_close(window, true)
    end
  end
end

local function clear_buffer(absolute_path)
  local bufs = vim.fn.getbufinfo { bufloaded = 1, buflisted = 1 }
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      if buf.hidden == 0 and (#bufs > 1 or view.View.float.enable) then
        local winnr = a.nvim_get_current_win()
        a.nvim_set_current_win(buf.windows[1])
        vim.cmd ":bn"
        if not view.View.float.enable then
          a.nvim_set_current_win(winnr)
        end
      end
      a.nvim_buf_delete(buf.bufnr, { force = true })
      if M.close_window then
        close_windows(buf.windows)
      end
      return
    end
  end
end

local function remove_dir(cwd)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == "string" then
    return utils.notify.error(handle)
  end

  while true do
    local name, t = luv.fs_scandir_next(handle)
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
      local success = luv.fs_unlink(new_cwd)
      if not success then
        return false
      end
      clear_buffer(new_cwd)
    end
  end

  return luv.fs_rmdir(cwd)
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
      if node.nodes ~= nil and not node.link_to then
        local success = remove_dir(node.absolute_path)
        if not success then
          return utils.notify.error("Could not remove " .. node.name)
        end
        events._dispatch_folder_removed(node.absolute_path)
      else
        local success = luv.fs_unlink(node.absolute_path)
        if not success then
          return utils.notify.error("Could not remove " .. node.name)
        end
        events._dispatch_file_removed(node.absolute_path)
        clear_buffer(node.absolute_path)
      end
      utils.notify.info(node.absolute_path .. " was properly removed.")
      if M.enable_reload then
        require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
      end
    end
  end)
end

function M.setup(opts)
  M.enable_reload = not opts.filesystem_watchers.enable
  M.close_window = opts.actions.remove_file.close_window
end

return M
