local a = vim.api
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local config = require'nvim-tree.config'
local icon_state = config.get_icon_state()
local get_diagnostics = vim.lsp.diagnostic.get_all

local M = {}

local function get_lowest_severity(diagnostics)
  local severity = math.huge
  for _, v in ipairs(diagnostics) do
    if v.severity < severity then
      severity = v.severity
    end
  end
  return severity
end

local sign_names = {
  { "NvimTreeSignError", "NvimTreeLspDiagnosticsError" },
  { "NvimTreeSignWarning", "NvimTreeLspDiagnosticsWarning" },
  { "NvimTreeSignInformation", "NvimTreeLspDiagnosticsInformation" },
  { "NvimTreeSignHint", "NvimTreeLspDiagnosticsHint" },
}

vim.fn.sign_define(sign_names[1][1], { text=icon_state.icons.lsp.error, texthl=sign_names[1][2]})
vim.fn.sign_define(sign_names[2][1], { text=icon_state.icons.lsp.warning, texthl=sign_names[2][2]})
vim.fn.sign_define(sign_names[3][1], { text=icon_state.icons.lsp.info, texthl=sign_names[3][2]})
vim.fn.sign_define(sign_names[4][1], { text=icon_state.icons.lsp.hint, texthl=sign_names[4][2]})

local signs = {}

local function add_sign(linenr, severity)
  local buf = view.View.bufnr
  if not a.nvim_buf_is_valid(buf) or not a.nvim_buf_is_loaded(buf) then return end
  local sign_name = sign_names[severity][1]
  table.insert(signs, vim.fn.sign_place(1, 'NvimTreeDiagnosticSigns', sign_name, buf, { lnum = linenr+1 }))
end

function M.update()
  local buffer_severity = {}

  for buf, diagnostics in pairs(get_diagnostics()) do
    if a.nvim_buf_is_valid(buf) then
      local bufname = a.nvim_buf_get_name(buf)
      if not buffer_severity[bufname] then
        local severity = get_lowest_severity(diagnostics)
        buffer_severity[bufname] = severity
      end
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
    if 0 < severity and severity < 5 then
      local node, line = utils.find_node(nodes, function(node)
        return node.absolute_path == bufname
      end)
      if node then add_sign(line, severity) end
    end
  end
end

return M
