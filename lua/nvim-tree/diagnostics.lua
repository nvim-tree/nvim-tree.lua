local a = vim.api
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local get_diagnostics = vim.lsp.diagnostic.get_all

local M = {}

local function get_highest_severity(diagnostics)
  local severity = 0
  for _, v in ipairs(diagnostics) do
    if v.severity > severity then
      severity = v.severity
    end
  end
  return severity
end

local sign_names = {
  { "NvimTreeSignHint", "NvimTreeLspDiagnosticsHint" },
  { "NvimTreeSignInformation", "NvimTreeLspDiagnosticsInformation" },
  { "NvimTreeSignWarning", "NvimTreeLspDiagnosticsWarning" },
  { "NvimTreeSignError", "NvimTreeLspDiagnosticsError" },
}

for _, v in ipairs(sign_names) do
  vim.fn.sign_define(v[1], { text="⚠", texthl=v[2]})
end

local signs = {}

local function add_sign(linenr, severity)
  local buf = view.View.bufnr
  if not vim.fn.bufexists(buf) or not vim.fn.bufloaded(buf) then return end
  local sign_name = sign_names[severity][1]
  table.insert(signs, vim.fn.sign_place(1, 'NvimTreeDiagnosticSigns', sign_name, buf, { lnum = linenr+1 }))
end

function M.update()
  local buffer_severity = {}

  for buf, diagnostics in pairs(get_diagnostics()) do
    local bufname = a.nvim_buf_get_name(buf)
    if not buffer_severity[bufname] then
      local severity = get_highest_severity(diagnostics)
      buffer_severity[bufname] = severity
    end
  end

  local nodes = require'nvim-tree.lib'.Tree.entries
  if #signs then
    vim.fn.sign_unplacelist(vim.tbl_map(function(sign)
      return {
        buffer = view.View.bufnr,
        group = "NvimTreeDiagnosticSigns",
        id = sign
      }
    end, signs))
    signs = {}
  end
  for bufname, severity in pairs(buffer_severity) do
    if severity > 0 then
      local node, line = utils.find_node(nodes, function(node)
        return node.absolute_path == bufname
      end)
      if node then add_sign(line, severity) end
    end
  end
end

return M
