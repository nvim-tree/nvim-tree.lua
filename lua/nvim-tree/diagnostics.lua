local a = vim.api
local get_diagnostics = vim.lsp.diagnostic.get_all

local M = {}

local diagnostics_per_bufname = {}

local function get_highest_diagnostic_severity(diagnostics)
  local hi_value = 0
  for _, v in ipairs(diagnostics) do
    if v.severity > hi_value then
      hi_value = v.severity
    end
  end
  return hi_value
end

local function find_node_with_name(tree, name)
  local i = 1
  for _, node in ipairs(tree) do
    if node.absolute_path == name then return node, i end
    if node.open and #node.entries > 0 then
      local n, idx = find_node_with_name(node.entries, name)
      i = i + idx
      if n then return n, i end
    end
    i = i + 1
  end
  return nil, i
end

vim.cmd "hi! NvimTreeLspDiagnostic gui=underline"

local function highlight_node(node, linenr)
  local buf = require'nvim-tree.lib'.Tree.bufnr
  if not vim.fn.bufexists(buf) or not vim.fn.bufloaded(buf) then return end
  local line = a.nvim_buf_get_lines(buf, linenr, linenr+1, false)[1]
  local starts_at = vim.fn.stridx(line, node.name)
  a.nvim_buf_add_highlight(buf, -1, 'NvimTreeLspDiagnostic', linenr, starts_at, -1)
end

function M.update()
  for buf, diagnostics in pairs(get_diagnostics()) do
    diagnostics_per_bufname[a.nvim_buf_get_name(buf)] = get_highest_diagnostic_severity(diagnostics)
  end

  vim.defer_fn(function()
    local tree = require'nvim-tree.lib'.Tree.entries
    for name, severity in pairs(diagnostics_per_bufname) do
      if severity > 0 then
        local node, line = find_node_with_name(tree, name)
        if node then highlight_node(node, line) end
      end
    end
  end, 100)
end

return M
