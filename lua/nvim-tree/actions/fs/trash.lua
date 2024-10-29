local core = require("nvim-tree.core")
local lib = require("nvim-tree.lib")
local notify = require("nvim-tree.notify")

local DirectoryLinkNode = require("nvim-tree.node.directory-link")
local DirectoryNode = require("nvim-tree.node.directory")

local M = {
  config = {},
}

local utils = require("nvim-tree.utils")
local events = require("nvim-tree.events")

---@param absolute_path string
local function clear_buffer(absolute_path)
  local bufs = vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 })
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      if buf.hidden == 0 and #bufs > 1 then
        local winnr = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(buf.windows[1])
        vim.cmd(":bn")
        vim.api.nvim_set_current_win(winnr)
      end
      vim.api.nvim_buf_delete(buf.bufnr, {})
      return
    end
  end
end

---@param node Node
function M.remove(node)
  local binary = M.config.trash.cmd:gsub(" .*$", "")
  if vim.fn.executable(binary) == 0 then
    notify.warn(string.format("trash.cmd '%s' is not an executable.", M.config.trash.cmd))
    return
  end

  local err_msg = ""
  local function on_stderr(_, data)
    err_msg = err_msg .. (data and table.concat(data, " "))
  end

  -- trashes a path (file or folder)
  local function trash_path(on_exit)
    local need_sync_wait = utils.is_windows
    local job = vim.fn.jobstart(M.config.trash.cmd .. " " .. vim.fn.shellescape(node.absolute_path), {
      detach = not need_sync_wait,
      on_exit = on_exit,
      on_stderr = on_stderr,
    })
    if need_sync_wait then
      vim.fn.jobwait({ job })
    end
  end

  local explorer = core.get_explorer()

  if node:is(DirectoryNode) and not node:is(DirectoryLinkNode) then
    trash_path(function(_, rc)
      if rc ~= 0 then
        notify.warn("trash failed: " .. err_msg .. "; please see :help nvim-tree.trash")
        return
      end
      events._dispatch_folder_removed(node.absolute_path)
      if not M.config.filesystem_watchers.enable and explorer then
        explorer:reload_explorer()
      end
    end)
  else
    events._dispatch_will_remove_file(node.absolute_path)
    trash_path(function(_, rc)
      if rc ~= 0 then
        notify.warn("trash failed: " .. err_msg .. "; please see :help nvim-tree.trash")
        return
      end
      events._dispatch_file_removed(node.absolute_path)
      clear_buffer(node.absolute_path)
      if not M.config.filesystem_watchers.enable and explorer then
        explorer:reload_explorer()
      end
    end)
  end
end

---@param node Node
function M.fn(node)
  if node.name == ".." then
    return
  end

  local function do_trash()
    M.remove(node)
  end

  if M.config.ui.confirm.trash then
    local prompt_select = "Trash " .. node.name .. "?"
    local prompt_input, items_short, items_long

    if M.config.ui.confirm.default_yes then
      prompt_input = prompt_select .. " Y/n: "
      items_short = { "", "n" }
      items_long = { "Yes", "No" }
    else
      prompt_input = prompt_select .. " y/N: "
      items_short = { "", "y" }
      items_long = { "No", "Yes" }
    end

    lib.prompt(prompt_input, prompt_select, items_short, items_long, "nvimtree_trash", function(item_short)
      utils.clear_prompt()
      if item_short == "y" or item_short == (M.config.ui.confirm.default_yes and "") then
        do_trash()
      end
    end)
  else
    do_trash()
  end
end

function M.setup(opts)
  M.config.ui = opts.ui
  M.config.trash = opts.trash
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
