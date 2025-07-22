local core = require("nvim-tree.core")
local utils = require("nvim-tree.utils")
local events = require("nvim-tree.events")
local lib = require("nvim-tree.lib")
local notify = require("nvim-tree.notify")

local DirectoryLinkNode = require("nvim-tree.node.directory-link")
local DirectoryNode = require("nvim-tree.node.directory")

local M = {
  config = {},
}

---@param windows integer[]
local function close_windows(windows)
  local explorer = core.get_explorer()

  -- Prevent from closing when the win count equals 1 or 2,
  -- where the win to remove could be the last opened.
  -- For details see #2503.
  if explorer and explorer.view.float.enable and #vim.api.nvim_list_wins() < 3 then
    return
  end

  for _, window in ipairs(windows) do
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end
end

---@param absolute_path string
local function clear_buffer(absolute_path)
  local explorer = core.get_explorer()
  local bufs = vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 })
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      local tree_winnr = vim.api.nvim_get_current_win()
      if buf.hidden == 0 and (#bufs > 1 or explorer and explorer.view.float.enable) then
        vim.api.nvim_set_current_win(buf.windows[1])
        vim.cmd(":bn")
      end
      vim.api.nvim_buf_delete(buf.bufnr, { force = true })
      if explorer and not explorer.view.float.quit_on_focus_loss then
        vim.api.nvim_set_current_win(tree_winnr)
      end
      if M.config.actions.remove_file.close_window then
        close_windows(buf.windows)
      end
      return
    end
  end
end

---@param cwd string
---@return boolean|nil
local function remove_dir(cwd)
  local handle, err = vim.loop.fs_scandir(cwd)
  if not handle then
    notify.error(err)
    return
  end

  while true do
    local name, _ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local new_cwd = utils.path_join({ cwd, name })

    -- Type must come from fs_stat and not fs_scandir_next to maintain sshfs compatibility
    local stat = vim.loop.fs_stat(new_cwd)
    ---@diagnostic disable-next-line: param-type-mismatch
    local lstat = vim.loop.fs_lstat(new_cwd)

    local type = stat and stat.type or nil
    -- Checks if file is a link file to ensure deletion of the symlink instead of the file it points to
    local ltype = lstat and lstat.type or nil

    if type == "directory" and ltype ~= "link" then
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

--- Remove a node, notify errors, dispatch events
---@param node Node
function M.remove(node)
  local notify_node = notify.render_path(node.absolute_path)
  if node:is(DirectoryNode) and not node:is(DirectoryLinkNode) then
    local success = remove_dir(node.absolute_path)
    if not success then
      notify.error("Could not remove " .. notify_node)
      return
    end
    events._dispatch_folder_removed(node.absolute_path)
  else
    events._dispatch_will_remove_file(node.absolute_path)
    local success = vim.loop.fs_unlink(node.absolute_path)
    if not success then
      notify.error("Could not remove " .. notify_node)
      return
    end
    events._dispatch_file_removed(node.absolute_path)
    clear_buffer(node.absolute_path)
  end
  notify.info(notify_node .. " was properly removed.")
end

---@param node Node
function M.fn(node)
  if node.name == ".." then
    return
  end

  local function do_remove()
    M.remove(node)
    local explorer = core.get_explorer()
    if not M.config.filesystem_watchers.enable and explorer then
      explorer:reload_explorer()
    end
  end

  if M.config.ui.confirm.remove then
    local prompt_select = "Remove " .. node.name .. "?"
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

    lib.prompt(prompt_input, prompt_select, items_short, items_long, "nvimtree_remove", function(item_short)
      utils.clear_prompt()
      if item_short == "y" or item_short == (M.config.ui.confirm.default_yes and "") then
        do_remove()
      end
    end)
  else
    do_remove()
  end
end

function M.setup(opts)
  M.config.ui = opts.ui
  M.config.actions = opts.actions
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
