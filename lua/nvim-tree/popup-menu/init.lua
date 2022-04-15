local a = vim.api

local M = {}

-- TODO: we need to test/fix this when we are using multiple tabs 
--       as pointed at:
--       https://github.com/kyazdani42/nvim-tree.lua/pull/1162/files/be376a7cbf7164a4a19535834d9019bc97559d4d#r850952305
local function get_node()
  local get_node_at_cursor = require'nvim-tree.lib'.get_node_at_cursor
  
  local current_node = get_node_at_cursor() 
  return current_node
end

local current_popup = nil 

function get_current_action(_winnr, _bufnr)
  local node = current_popup.current_node 
  local cur_pos = a.nvim_win_get_cursor(_winnr)[1]
  local current_action = a.nvim_buf_get_lines(_bufnr, cur_pos -1, cur_pos, false)[1]
  
  local run_fn = M.actions[current_action]
  
  for _,v in pairs(require'nvim-tree.actions'.mappings) do
    if v.action == run_fn then      
      require'nvim-tree.actions'.keypress_funcs[run_fn](node)
    end
    M.close_window()
  end
end

local function setup_mappings()
  -- TODO: pass mappings as arguments from setup or default
  a.nvim_buf_set_keymap(bufnr, 'n', '<CR>', string.format([[:lua get_current_action(%s, %s)<CR>]], current_popup.winnr, current_popup.bufnr), { noremap = true, silent = true })
  a.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', [[:lua require("nvim-tree.popup-menu").close_window()<CR>]], { noremap = true, silent = true } )
end

local function setup_window(actions)
  local max_width = vim.fn.max(vim.tbl_map(function(n) return #n end, vim.tbl_keys(actions)))
  winnr =  a.nvim_open_win(0, true, {
    col = 0, 
    row = 1,
    relative = 'cursor',

    width = max_width + 1,
    height = vim.tbl_count(actions),
    style = 'minimal'
  })
  
  bufnr = a.nvim_create_buf(false, true)
  a.nvim_buf_set_lines(bufnr, 0, -1, false, vim.tbl_keys(actions))
  a.nvim_win_set_buf(winnr, bufnr)
  
  current_popup = {
    winnr = winnr,
    bufnr = bufnr,
    current_node = get_node()
  }
  
  -- this take care of closing the menu if for some reason lose focus 
  vim.cmd [[augroup NvimTreeCloseMenu ]]
  vim.cmd(string.format([[autocmd BufLeave,FocusLost <buffer=%s> :lua require'nvim-tree.popup-menu'.close_window()]], current_popup.bufnr))
  vim.cmd [[augroup END]]
end

function M.open_window()
  setup_window(M.actions)
  setup_mappings()
end

function M.close_window()
  if current_popup ~= nil then
    a.nvim_win_close(current_popup.winnr, { force = true })

    current_popup = nil
  end
end

function M.setup(opts)
  if M.actions == nil then 
    M.actions = require("nvim-tree.popup-menu.default_actions").actions
  else
    -- maybe we need to pass an option so the user can keep 
    -- the default and add the custom actions
    M.actions = opts.menu.actions
  end
end

return M
