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

local severity_levels = { Error = 1, Warning = 2, Information = 3, Hint = 4 }
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

local function from_nvim_lsp()
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

  return buffer_severity
end

local function from_coc()
  if vim.g.coc_service_initialized ~= 1 then
    return {}
  end

  local diagnostic_list = vim.fn.CocAction("diagnosticList")
  if type(diagnostic_list) ~='table' or vim.tbl_isempty(diagnostic_list) then
    return {}
  end

  local buffer_severity = {}
  local diagnostics = {}

  for _, diagnostic in ipairs(diagnostic_list) do
    local bufname = diagnostic.file
    local severity = severity_levels[diagnostic.severity]

    local severity_list = diagnostics[bufname] or {}
    table.insert(severity_list, severity)
    diagnostics[bufname] = severity_list
	end

  for bufname, severity_list in pairs(diagnostics) do
    if not buffer_severity[bufname] then
      local severity = math.min(unpack(severity_list))
      buffer_severity[bufname] = severity
    end
  end

  return buffer_severity
end

function M.update()
  local buffer_severity
  if vim.g.coc_service_initialized == 1 then
    buffer_severity = from_coc()
  else
    buffer_severity = from_nvim_lsp()
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
