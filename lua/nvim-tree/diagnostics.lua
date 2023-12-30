local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local log = require "nvim-tree.log"

local M = {}

---COC severity level strings to LSP severity levels
---@enum COC_SEVERITY_LEVELS
local COC_SEVERITY_LEVELS = {
  Error = 1,
  Warning = 2,
  Information = 3,
  Hint = 4,
}

---Absolute Node path to LSP severity level
---@alias NodeSeverities table<string, lsp.DiagnosticSeverity>

---@class DiagStatus
---@field value lsp.DiagnosticSeverity|nil
---@field cache_version integer

--- The buffer-severity mappings derived during the last diagnostic list update.
---@type NodeSeverities
local NODE_SEVERITIES = {}

---The cache version number of the buffer-severity mappings.
---@type integer
local NODE_SEVERITIES_VERSION = 0

---@param path string
---@return string
local function uniformize_path(path)
  return utils.canonical_path(path:gsub("\\", "/"))
end

---Marshal severities from LSP. Does nothing when LSP disabled.
---@return NodeSeverities
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
        local bufname = uniformize_path(vim.api.nvim_buf_get_name(buf))
        local severity = diagnostic.severity
        local highest_severity = buffer_severity[bufname] or severity
        buffer_severity[bufname] = math.min(highest_severity, severity)
      end
    end
  end

  return buffer_severity
end

---Severity is within diagnostics.severity.min, diagnostics.severity.max
---@param severity lsp.DiagnosticSeverity
---@param config table
---@return boolean
local function is_severity_in_range(severity, config)
  return config.max <= severity and severity <= config.min
end

---Handle any COC exceptions, preventing any propagation
---@param err string
local function handle_coc_exception(err)
  log.line("diagnostics", "handle_coc_exception: %s", vim.inspect(err))
  local notify = true

  -- avoid distractions on interrupts (CTRL-C)
  if err:find "Vim:Interrupt" or err:find "Keyboard interrupt" then
    notify = false
  end

  if notify then
    require("nvim-tree.notify").error("Diagnostics update from coc.nvim failed. " .. vim.inspect(err))
  end
end

---COC service initialized
---@return boolean
local function is_using_coc()
  return vim.g.coc_service_initialized == 1
end

---Marshal severities from COC. Does nothing when COC service not started.
---@return NodeSeverities
local function from_coc()
  if not is_using_coc() then
    return {}
  end

  local ok, diagnostic_list = xpcall(function()
    return vim.fn.CocAction "diagnosticList"
  end, handle_coc_exception)
  if not ok or type(diagnostic_list) ~= "table" or vim.tbl_isempty(diagnostic_list) then
    return {}
  end

  local buffer_severity = {}
  for _, diagnostic in ipairs(diagnostic_list) do
    local bufname = uniformize_path(diagnostic.file)
    local coc_severity = COC_SEVERITY_LEVELS[diagnostic.severity]
    local highest_severity = buffer_severity[bufname] or coc_severity
    if is_severity_in_range(highest_severity, M.severity) then
      buffer_severity[bufname] = math.min(highest_severity, coc_severity)
    end
  end

  return buffer_severity
end

---Maybe retrieve severity level from the cache
---@param node Node
---@return DiagStatus
local function from_cache(node)
  local nodepath = uniformize_path(node.absolute_path)
  local max_severity = nil
  if not node.nodes then
    -- direct cache hit for files
    max_severity = NODE_SEVERITIES[nodepath]
  else
    -- dirs should be searched in the list of cached buffer names by prefix
    for bufname, severity in pairs(NODE_SEVERITIES) do
      local node_contains_buf = vim.startswith(bufname, nodepath .. "/")
      if node_contains_buf then
        if severity == M.severity.max then
          max_severity = severity
          break
        else
          max_severity = math.min(max_severity or severity, severity)
        end
      end
    end
  end
  return { value = max_severity, cache_version = NODE_SEVERITIES_VERSION }
end

---Fired on DiagnosticChanged and CocDiagnosticChanged events:
---debounced retrieval, cache update, version increment and draw
function M.update()
  if not M.enable then
    return
  end
  utils.debounce("diagnostics", M.debounce_delay, function()
    local profile = log.profile_start "diagnostics update"
    if is_using_coc() then
      NODE_SEVERITIES = from_coc()
    else
      NODE_SEVERITIES = from_nvim_lsp()
    end
    NODE_SEVERITIES_VERSION = NODE_SEVERITIES_VERSION + 1
    if log.enabled "diagnostics" then
      for bufname, severity in pairs(NODE_SEVERITIES) do
        log.line("diagnostics", "Indexing bufname '%s' with severity %d", bufname, severity)
      end
    end
    log.profile_end(profile)
    if view.is_buf_valid(view.get_bufnr()) then
      require("nvim-tree.renderer").draw()
    end
  end)
end

---Maybe retrieve diagnostic status for a node.
---Returns cached value when node's version matches.
---@param node Node
---@return DiagStatus|nil
function M.get_diag_status(node)
  if not M.enable then
    return nil
  end

  -- dir but we shouldn't show on dirs at all
  if node.nodes ~= nil and not M.show_on_dirs then
    return nil
  end

  -- here, we do a lazy update of the diagnostic status carried by the node.
  -- This is by design, as diagnostics and nodes live in completely separate
  -- worlds, and this module is the link between the two
  if not node.diag_status or node.diag_status.cache_version < NODE_SEVERITIES_VERSION then
    node.diag_status = from_cache(node)
  end

  -- file
  if not node.nodes then
    return node.diag_status
  end

  -- dir is closed or we should show on open_dirs
  if not node.open or M.show_on_open_dirs then
    return node.diag_status
  end
  return nil
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
