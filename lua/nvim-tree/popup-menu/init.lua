local a = vim.api

local get_node = require('nvim-tree.lib').get_node_at_cursor
local get_explorer = require('nvim-tree.core').get_explorer

local M = {}

M.is_open = false
M.win = 0
M.bufnr = 0

local actions = {
 ['copy'] = require('nvim-tree.actions.copy-paste').copy 
}

M.mappings = {
  ['<Esc>'] = 'close_menu',
  ['<CR>'] = 'on_selection',
}

local ns_PopupMenu = a.nvim_create_namespace('ns_NvimTreePopupMenu')

local function create_buf()
  if vim.fn.bufexists("NvimTreePopupMenuBuf") == 1 then
    a.nvim_buf_delete(vim.fn.bufnr('NvimTreePopupMenuBuf'), {} )
  end    
  local buf = a.nvim_create_buf(false, true)
  a.nvim_buf_set_name(buf, 'NvimTreePopupMenuBuf')
  M.bufnr = buf
  
  return buf
end

function M.open_menu()
  if M.is_open == true then
    close_menu()
  end

  create_buf()
  local win_opts = {
    width = 10, -- we should set this as NvimExplorer width
    height = 1, -- TODO: Set this as length of actions, as for now I'm not able to do it.
    row = 1,
    col = 0,
    style = 'minimal',
    relative = 'cursor'
  }

  local win_ui = a.nvim_open_win(M.bufnr, true, win_opts)
  M.is_open = true
  M.win = win_ui
  set_actions(actions)
  
  -- TODO: Convert this to nvim lua api.
  --       at this time on my machine with nvim 0.7.0-dev+1328-gfb5587d2b
  --       keep yelling that "event" must be an array or string
  local au_group = a.nvim_create_augroup('NvimSelectionAuGroup', { clear = true })
  vim.cmd(string.format([[
      augroup NvimSelectionAuGroup
      au! CursorMoved <buffer=%s> :lua require('nvim-tree.popup-menu').add_hl_to_selection()
      augroup END
    ]], M.bufnr))

  -- mappings on open window
  -- should we pass this on separate file?
  for k, v in pairs(M.mappings) do
      if v ~= nil then
        a.nvim_buf_set_keymap(
          M.bufnr, 
          'n', k,
          string.format([[:lua %s()<CR>]], v), { noremap = true, silent = true })
        end
      end
  end

function close_menu()
  a.nvim_win_close(M.win, true)
  M.is_open = false
end

function set_actions(tbl)
  a.nvim_buf_set_lines(M.bufnr, 0, 1, true, vim.tbl_keys(tbl))
end

function M.add_hl_to_selection()
  if M.is_open == true then
    local row = a.nvim_win_get_cursor(M.win)[1]
    local sel_item = a.nvim_buf_get_lines(M.bufnr, row -1, row, {})[1] -- should we pass this as module params to let user customize action on current selected item?

    -- clear prev highlights
    a.nvim_buf_clear_namespace(M.bufnr, ns_PopupMenu, 0, -1)
    
    a.nvim_buf_add_highlight(
      M.bufnr,
      ns_PopupMenu,
      'Error',
      row -1,
      0,
      -1
    )
  end
end

function on_selection()
  local row = a.nvim_win_get_cursor(M.win)[1]
  local sel_item = a.nvim_buf_get_lines(M.bufnr, row -1, row, {})[1] -- should we pass this as module params to let user customize action on current selected item?
  
  actions[sel_item](get_node())
  close_menu()
end

return M
