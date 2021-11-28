local M = {}

local lib = require'nvim-tree.lib'
local utils = require'nvim-tree.utils'
local events = require'nvim-tree.events'
local api = vim.api

local function clear_buffer(absolute_path)
  local bufs = vim.fn.getbufinfo({bufloaded = 1, buflisted = 1})
  for _, buf in pairs(bufs) do
    if buf.name == absolute_path then
      if buf.hidden == 0 and #bufs > 1 then
        local winnr = api.nvim_get_current_win()
        api.nvim_set_current_win(buf.windows[1])
        vim.cmd(':bn')
        api.nvim_set_current_win(winnr)
      end
      vim.api.nvim_buf_delete(buf.bufnr, {})
      return
    end
  end
end

function M.trash_node(node, cfg)
  if node.name == '..' then return end

  -- configs
  if cfg.is_unix then
    if cfg.trash.cmd == nil then cfg.trash.cmd = 'trash' end
    if cfg.trash.require_confirm  == nil then cfg.trash.require_confirm  = true end
  else
    print('trash is currently a UNIX only feature!')
  end

  -- trashes a path (file or folder)
  local function trash_path(on_exit)
    vim.fn.jobstart(cfg.trash.cmd.." "..node.absolute_path, {
      detach = true,
      on_exit = on_exit,
    })
  end

  local is_confirmed = true

  -- confirmation prompt
  if cfg.trash.require_confirm then
    is_confirmed = false
    print("Trash " ..node.name.. " ? y/n")
    local ans = utils.get_user_input_char()
    if ans:match('^y') then is_confirmed = true end
    utils.clear_prompt()
  end

  -- trashing
  if is_confirmed then
    if node.entries ~= nil and not node.link_to then
      trash_path(function()
        events._dispatch_folder_removed(node.absolute_path)
        lib.refresh_tree()
      end)
    else
      trash_path(function()
        events._dispatch_file_removed(node.absolute_path)
        clear_buffer(node.absolute_path)
        lib.refresh_tree()
      end)
    end

  end
end

return M
