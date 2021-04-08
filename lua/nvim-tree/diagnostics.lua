local a = vim.api
local utils = require'nvim-tree.utils'
local get_diagnostics = vim.lsp.diagnostic.get_all

local M = {}

local function get_severity(diagnostics)
  for _, v in ipairs(diagnostics) do
    if v.severity > 0 then
      return v.severity
    end
  end
  return 0
end

local function highlight_node(node, linenr)
  local buf = require'nvim-tree.lib'.Tree.bufnr
  if not vim.fn.bufexists(buf) or not vim.fn.bufloaded(buf) then return end
  local line = a.nvim_buf_get_lines(buf, linenr, linenr+1, false)[1]
  local starts_at = vim.fn.stridx(line, node.name)
  a.nvim_buf_add_highlight(buf, -1, 'NvimTreeLspDiagnostics', linenr, starts_at, -1)
end


function M.update()
  local buffer_severity = {}

  for buf, diagnostics in pairs(get_diagnostics()) do
    local bufname = a.nvim_buf_get_name(buf)
    if not buffer_severity[bufname] then
      local severity = get_severity(diagnostics)
      buffer_severity[bufname] = severity
    end
  end

  vim.defer_fn(function()
    local nodes = require'nvim-tree.lib'.Tree.entries
    for bufname, severity in pairs(buffer_severity) do
      if severity > 0 then
        local node, line = utils.find_node(nodes, function(node)
          return node.absolute_path == bufname
        end)
        if node then highlight_node(node, line) end
      end
    end
  end, 100)
end

return M
