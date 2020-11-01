local M = {}

local explorer = nil

M.setup = require'nvim-tree.config'.setup
M.close = require'nvim-tree.buffers.tree'.close

function M.redraw()
  local buffers_tree = require'nvim-tree.buffers.tree'
  vim.defer_fn(
    function()
      local should_redraw = #vim.tbl_keys(buffers_tree.windows) > 0
      if should_redraw then
        buffers_tree.open()
      end
    end, 1)
end

function M.open()
  explorer = require'nvim-tree.explorer'.Explorer:new()
  local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree, explorer.cwd)
  if require'nvim-tree.buffers.tree'.open() == 'norestore' then
    require'nvim-tree.buffers.tree'.render(lines, highlights)
  end
end

local function cd(to)
  if not to or #to == 0 then return end
  vim.cmd(":cd "..to)
  explorer = require'nvim-tree.explorer'.Explorer:new()
  local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree, explorer.cwd)
  require'nvim-tree.buffers.tree'.render(lines, highlights)
end

function M.open_file(mode)
  local node = explorer:get_node_under_cursor()

  if not node then
    local parent_cwd = explorer.cwd:gsub('[^/]*$', '')
    return cd(parent_cwd)
  end

  if node.entries ~= nil then
    explorer:switch_open_dir(node)
    local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree, explorer.cwd)
    return require'nvim-tree.buffers.tree'.render(lines, highlights)
  end

  local config = require'nvim-tree.config'.config
  local nextw = config.side == 'left' and 'l' or 'h'
  local prevw = config.side == 'left' and 'h' or 'l'

  if mode == 'vsplit' then
    vim.cmd("vnew "..node.absolute_path)
  elseif mode == 'split' then
    vim.cmd("wincmd "..nextw.." | new "..node.absolute_path)
  elseif mode == 'tab' then
    vim.cmd("tabnew "..node.absolute_path)
  elseif mode == 'preview' then
    vim.cmd("wincmd "..nextw.." | e "..node.absolute_path.." | wincmd "..prevw)
  else
    local numwins = #vim.api.nvim_list_wins()
    if numwins > 1 then
      vim.cmd("wincmd "..nextw.." | e "..node.absolute_path)
    else
      vim.cmd("vnew "..node.absolute_path)
    end
  end

  if config.close_on_open_file and mode ~= 'preview' then
    require'nvim-tree.buffers.tree'.close()
  else
    require'nvim-tree.buffers.tree'.resize(false)
  end
end

function M.rename_file()
  local node, idx = explorer:get_node_under_cursor()
  if not node then return end
  require'nvim-tree.buffers.popups'.rename(node, idx+1)
end

return M
