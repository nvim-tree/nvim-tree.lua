local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local core = require "nvim-tree.core"
local log = require "nvim-tree.log"

local M = {}

local severity_levels = {
  Error = 1,
  Warning = 2,
  Information = 3,
  Hint = 4,
}

---@return table
local function from_nvim_lsp()
  local buffer_severity = {}

  local is_disabled = false
  if vim.fn.has "nvim-0.9" == 1 then
    is_disabled = vim.diagnostic.is_disabled()
  end

  if not is_disabled then
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
  end

  return buffer_severity
end

---@param severity integer
---@param config table
---@return boolean
local function is_severity_in_range(severity, config)
  return config.max <= severity and severity <= config.min
end

---@return table
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

function M.update()
  if not M.enable or not core.get_explorer() or not view.is_buf_valid(view.get_bufnr()) then
    return
  end
  utils.debounce("diagnostics", M.debounce_delay, function()
    local profile = log.profile_start "diagnostics update"
    log.line("diagnostics", "update")

    local buffer_severity
    if is_using_coc() then
      buffer_severity = from_coc()
    else
      buffer_severity = from_nvim_lsp()
    end

    local nodes_by_line = utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())
    for _, node in pairs(nodes_by_line) do
      node.diag_status = nil
    end

    for bufname, severity in pairs(buffer_severity) do
      local bufpath = utils.canonical_path(bufname)
      log.line("diagnostics", " bufpath '%s' severity %d", bufpath, severity)
      if 0 < severity and severity < 5 then
        for line, node in pairs(nodes_by_line) do
          local nodepath = utils.canonical_path(node.absolute_path)
          log.line("diagnostics", "  %d checking nodepath '%s'", line, nodepath)

          local node_contains_buf = vim.startswith(bufpath:gsub("\\", "/"), nodepath:gsub("\\", "/") .. "/")
          if M.show_on_dirs and node_contains_buf and (not node.open or M.show_on_open_dirs) then
            log.line("diagnostics", " matched fold node '%s'", node.absolute_path)
            node.diag_status = severity
          elseif nodepath == bufpath then
            log.line("diagnostics", " matched file node '%s'", node.absolute_path)
            node.diag_status = severity
          end
        end
      end
    end
    log.profile_end(profile)
    require("nvim-tree.renderer").draw()
  end)
end

function M.setup(opts)
  M.enable = opts.diagnostics.enable
  M.debounce_delay = opts.diagnostics.debounce_delay
  M.severity = opts.diagnostics.severity

  if M.enable then
    log.line("diagnostics", "setup")
  end

  M.show_on_dirs = opts.diagnostics.show_on_dirs
  M.show_on_open_dirs = opts.diagnostics.show_on_open_dirs
end

return M
