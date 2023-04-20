local view = require "nvim-tree.view"
local core = require "nvim-tree.core"
local log = require "nvim-tree.log"

local M = {}

local GROUP = "NvimTreeDiagnosticSigns"

local severity_levels = { Error = 1, Warning = 2, Information = 3, Hint = 4 }
local sign_names = {
  { "NvimTreeSignError", "NvimTreeLspDiagnosticsError" },
  { "NvimTreeSignWarning", "NvimTreeLspDiagnosticsWarning" },
  { "NvimTreeSignInformation", "NvimTreeLspDiagnosticsInformation" },
  { "NvimTreeSignHint", "NvimTreeLspDiagnosticsHint" },
}

function M.get_sign(severity)
  if not severity then
    return nil
  end

  return M.diagnostic_icons[severity]
end

function M.add_sign(linenr, severity)
  local buf = view.get_bufnr()
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local sign_name = sign_names[severity][1]
  vim.fn.sign_place(0, GROUP, sign_name, buf, { lnum = linenr, priority = 2 })
end

local function from_nvim_lsp()
  local buffer_severity = {}

  for _, diagnostic in ipairs(vim.diagnostic.get(nil, { severity = M.severity })) do
    local buf = diagnostic.bufnr
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      local lowest_severity = buffer_severity[bufname]
      if not lowest_severity or diagnostic.severity < lowest_severity then
        buffer_severity[bufname] = diagnostic.severity
      end
    end
  end

  return buffer_severity
end

local function is_severity_in_range(severity, config)
  return config.max <= severity and severity <= config.min
end

local function from_coc()
  if vim.g.coc_service_initialized ~= 1 then
    return {}
  end

  local diagnostic_list = vim.fn.CocAction "diagnosticList"
  if type(diagnostic_list) ~= "table" or vim.tbl_isempty(diagnostic_list) then
    return {}
  end

  local diagnostics = {}
  for _, diagnostic in ipairs(diagnostic_list) do
    local bufname = diagnostic.file
    local coc_severity = severity_levels[diagnostic.severity]

    local serverity = diagnostics[bufname] or vim.diagnostic.severity.HINT
    diagnostics[bufname] = math.min(coc_severity, serverity)
  end

  local buffer_severity = {}
  for bufname, severity in pairs(diagnostics) do
    if is_severity_in_range(severity, M.severity) then
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

  vim.fn.sign_unplace(GROUP)
end

function M.get_diagnostics()
  if not M.enable or not core.get_explorer() or not view.is_buf_valid(view.get_bufnr()) then
    return {}
  end

  if is_using_coc() then
    return from_coc()
  else
    return from_nvim_lsp()
  end
end

local links = {
  NvimTreeLspDiagnosticsError = "DiagnosticError",
  NvimTreeLspDiagnosticsWarning = "DiagnosticWarn",
  NvimTreeLspDiagnosticsInformation = "DiagnosticInfo",
  NvimTreeLspDiagnosticsHint = "DiagnosticHint",
}

function M.setup(opts)
  M.enable = opts.diagnostics.enable
  M.debounce_delay = opts.diagnostics.debounce_delay
  M.severity = opts.diagnostics.severity
  M.diagnostic_icons = {
    { str = opts.diagnostics.icons.error, hl = sign_names[1][2] },
    { str = opts.diagnostics.icons.warning, hl = sign_names[2][2] },
    { str = opts.diagnostics.icons.info, hl = sign_names[3][2] },
    { str = opts.diagnostics.icons.hint, hl = sign_names[4][2] },
  }

  if opts.renderer.icons.diagnostic_placement == "signcolumn" then
    vim.fn.sign_define(sign_names[1][1], { text = opts.diagnostics.icons.error, texthl = sign_names[1][2] })
    vim.fn.sign_define(sign_names[2][1], { text = opts.diagnostics.icons.warning, texthl = sign_names[2][2] })
    vim.fn.sign_define(sign_names[3][1], { text = opts.diagnostics.icons.info, texthl = sign_names[3][2] })
    vim.fn.sign_define(sign_names[4][1], { text = opts.diagnostics.icons.hint, texthl = sign_names[4][2] })
  end

  if M.enable then
    log.line("diagnostics", "setup")
  end

  M.show_on_dirs = opts.diagnostics.show_on_dirs
  M.show_on_open_dirs = opts.diagnostics.show_on_open_dirs

  for lhs, rhs in pairs(links) do
    vim.cmd("hi def link " .. lhs .. " " .. rhs)
  end
end

return M
