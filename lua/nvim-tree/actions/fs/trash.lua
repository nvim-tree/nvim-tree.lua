local lib = require "nvim-tree.lib"
local notify = require "nvim-tree.notify"

local M = {
  config = {
    is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win32unix" == 1,
    is_macos = vim.fn.has "mac" == 1 or vim.fn.has "macunix" == 1,
    is_unix = vim.fn.has "unix" == 1,
  },
}

local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"

local function clear_buffer(absolute_path)
  local bufs = vim.fn.getbufinfo { bufloaded = 1, buflisted = 1 }
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      if buf.hidden == 0 and #bufs > 1 then
        local winnr = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(buf.windows[1])
        vim.cmd ":bn"
        vim.api.nvim_set_current_win(winnr)
      end
      vim.api.nvim_buf_delete(buf.bufnr, {})
      return
    end
  end
end

function M.fn(node)
  if node.name == ".." then
    return
  end

  -- configs
  if M.config.is_unix then
    if M.config.trash.cmd == nil then
      M.config.trash.cmd = "trash"
    end
    if M.config.trash.require_confirm == nil then
      M.config.trash.require_confirm = true
    end
  else
    notify.warn "Trash is currently a UNIX only feature!"
    return
  end

  local binary = M.config.trash.cmd:gsub(" .*$", "")
  if vim.fn.executable(binary) == 0 then
    notify.warn(binary .. " is not executable.")
    return
  end

  local err_msg = ""
  local function on_stderr(_, data)
    err_msg = err_msg .. (data and table.concat(data, " "))
  end

  -- trashes a path (file or folder)
  local function trash_path(on_exit)
    vim.fn.jobstart(M.config.trash.cmd .. ' "' .. node.absolute_path .. '"', {
      detach = true,
      on_exit = on_exit,
      on_stderr = on_stderr,
    })
  end

  local function do_trash()
    if node.nodes ~= nil and not node.link_to then
      trash_path(function(_, rc)
        if rc ~= 0 then
          notify.warn("trash failed: " .. err_msg .. "; please see :help nvim-tree.trash")
          return
        end
        events._dispatch_folder_removed(node.absolute_path)
        if M.enable_reload then
          require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
        end
      end)
    else
      trash_path(function(_, rc)
        if rc ~= 0 then
          notify.warn("trash failed: " .. err_msg .. "; please see :help nvim-tree.trash")
          return
        end
        events._dispatch_file_removed(node.absolute_path)
        clear_buffer(node.absolute_path)
        if M.enable_reload then
          require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
        end
      end)
    end
  end

  if M.config.trash.require_confirm then
    local prompt_select = "Trash " .. node.name .. " ?"
    local prompt_input = prompt_select .. " y/n: "
    lib.prompt(prompt_input, prompt_select, { "y", "n" }, { "Yes", "No" }, function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        do_trash()
      end
    end)
  else
    do_trash()
  end
end

function M.setup(opts)
  M.config.trash = opts.trash or {}
  M.enable_reload = not opts.filesystem_watchers.enable
end

return M
