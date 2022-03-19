local a = vim.api
local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local core = require "nvim-tree.core"

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

local signs = {}

local function add_sign(linenr, severity)
  local buf = view.get_bufnr()
  if not a.nvim_buf_is_valid(buf) or not a.nvim_buf_is_loaded(buf) then
    return
  end
  local sign_name = sign_names[severity][1]
  table.insert(signs, vim.fn.sign_place(1, "NvimTreeDiagnosticSigns", sign_name, buf, { lnum = linenr + 1 }))
end

local function from_nvim_lsp()
  local buffer_severity = {}

  -- vim.lsp.diagnostic.get_all was deprecated in nvim 0.7 and replaced with vim.diagnostic.get
  -- This conditional can be removed when the minimum required version of nvim is changed to 0.7.
  if vim.diagnostic then
    -- nvim version >= 0.7
    for _, diagnostic in ipairs(vim.diagnostic.get()) do
      local buf = diagnostic.bufnr
      if a.nvim_buf_is_valid(buf) then
        local bufname = a.nvim_buf_get_name(buf)
        local lowest_severity = buffer_severity[bufname]
        if not lowest_severity or diagnostic.severity < lowest_severity then
          buffer_severity[bufname] = diagnostic.severity
        end
      end
    end
  else
    -- nvim version < 0.7
    for buf, diagnostics in pairs(vim.lsp.diagnostic.get_all()) do
      if a.nvim_buf_is_valid(buf) then
        local bufname = a.nvim_buf_get_name(buf)
        if not buffer_severity[bufname] then
          local severity = get_lowest_severity(diagnostics)
          buffer_severity[bufname] = severity
        end
      end
    end
  end

  return buffer_severity
end

local function from_coc()
  if vim.g.coc_service_initialized ~= 1 then
    return {}
  end

  local diagnostic_list = vim.fn.CocAction "diagnosticList"
  if type(diagnostic_list) ~= "table" or vim.tbl_isempty(diagnostic_list) then
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

local function is_using_coc()
  return vim.g.coc_service_initialized == 1
end

function M.clear()
  if not M.enable or not view.is_buf_valid(view.get_bufnr()) then
    return
  end

  if #signs then
    vim.fn.sign_unplacelist(vim.tbl_map(function(sign)
      return {
        buffer = view.get_bufnr(),
        group = "NvimTreeDiagnosticSigns",
        id = sign,
      }
    end, signs))
    signs = {}
  end
end

function M.update()
  if not M.enable or not core.get_explorer() or not view.is_buf_valid(view.get_bufnr()) then
    return
  end
  local buffer_severity
  if is_using_coc() then
    buffer_severity = from_coc()
  else
    buffer_severity = from_nvim_lsp()
  end

  M.clear()
  for bufname, severity in pairs(buffer_severity) do
    if 0 < severity and severity < 5 then
      local node, line = utils.find_node(core.get_explorer().nodes, function(node)
        if M.show_on_dirs and not node.open then
          return vim.startswith(bufname, node.absolute_path)
        else
          return node.absolute_path == bufname
        end
      end)
      if node then
        add_sign(line, severity)
      end
    end
  end
end

local has_06 = vim.fn.has "nvim-0.6" == 1
local links = {
  NvimTreeLspDiagnosticsError = has_06 and "DiagnosticError" or "LspDiagnosticsDefaultError",
  NvimTreeLspDiagnosticsWarning = has_06 and "DiagnosticWarn" or "LspDiagnosticsDefaultWarning",
  NvimTreeLspDiagnosticsInformation = has_06 and "DiagnosticInfo" or "LspDiagnosticsDefaultInformation",
  NvimTreeLspDiagnosticsHint = has_06 and "DiagnosticHint" or "LspDiagnosticsDefaultHint",
}

function M.setup(opts)
  M.enable = opts.diagnostics.enable
  M.show_on_dirs = opts.diagnostics.show_on_dirs
  vim.fn.sign_define(sign_names[1][1], { text = opts.diagnostics.icons.error, texthl = sign_names[1][2] })
  vim.fn.sign_define(sign_names[2][1], { text = opts.diagnostics.icons.warning, texthl = sign_names[2][2] })
  vim.fn.sign_define(sign_names[3][1], { text = opts.diagnostics.icons.info, texthl = sign_names[3][2] })
  vim.fn.sign_define(sign_names[4][1], { text = opts.diagnostics.icons.hint, texthl = sign_names[4][2] })

  for lhs, rhs in pairs(links) do
    vim.cmd("hi def link " .. lhs .. " " .. rhs)
  end

  if M.enable then
    if has_06 then
      vim.cmd "au DiagnosticChanged * lua require'nvim-tree.diagnostics'.update()"
    else
      vim.cmd "au User LspDiagnosticsChanged lua require'nvim-tree.diagnostics'.update()"
    end
  end
end

return M
