local core = require("nvim-tree.core")
local utils = require("nvim-tree.utils")
local view = require("nvim-tree.view")
local log = require("nvim-tree.log")

local DirectoryNode = require("nvim-tree.node.directory")

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
---@alias NodeSeverities table<string, vim.diagnostic.Severity>

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
  if err:find("Vim:Interrupt") or err:find("Keyboard interrupt") then
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
    return vim.fn.CocAction("diagnosticList")
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
  if not node:is(DirectoryNode) then
    -- direct cache hit for files
    max_severity = NODE_SEVERITIES[nodepath]
  else
    -- dirs should be searched in the list of cached buffer names by prefix
    for bufname, severity in pairs(NODE_SEVERITIES) do
      local node_contains_buf = vim.startswith(bufname, nodepath .. "/")
      if node_contains_buf then
        if not max_severity or severity < max_severity then
          max_severity = severity
        end
      end
    end
  end
  return { value = max_severity, cache_version = NODE_SEVERITIES_VERSION }
end

---Fired on DiagnosticChanged for a single buffer.
---This will be called on set and reset of diagnostics.
---On disabling LSP, a reset event will be sent for all buffers.
---@param ev table standard event with data.diagnostics populated
function M.update_lsp(ev)
  if not M.enable or not ev or not ev.data or not ev.data.diagnostics then
    return
  end

  local profile_event = log.profile_start("DiagnosticChanged event")

  local diagnostics = vim.diagnostic.get(ev.buf)

  -- use the buffer from the event, as ev.data.diagnostics will be empty on resolved diagnostics
  local bufname = uniformize_path(vim.api.nvim_buf_get_name(ev.buf))

  ---@type vim.diagnostic.Severity?
  local new_severity = nil

  -- most severe (lowest) severity in user range
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.severity >= M.severity.max and diagnostic.severity <= M.severity.min then
      if not new_severity or diagnostic.severity < new_severity then
        new_severity = diagnostic.severity
      end
    end
  end

  -- record delta and schedule a redraw
  if new_severity ~= NODE_SEVERITIES[bufname] then
    NODE_SEVERITIES[bufname] = new_severity
    NODE_SEVERITIES_VERSION = NODE_SEVERITIES_VERSION + 1

    utils.debounce("DiagnosticChanged redraw", M.debounce_delay, function()
      local profile_redraw = log.profile_start("DiagnosticChanged redraw")

      local explorer = core.get_explorer()
      if explorer then
        explorer.renderer:draw()
      end

      log.profile_end(profile_redraw)
    end)
  end

  log.profile_end(profile_event)
end

---Fired on CocDiagnosticChanged events:
---debounced retrieval, cache update, version increment and draw
function M.update_coc()
  if not M.enable then
    return
  end
  utils.debounce("CocDiagnosticChanged update", M.debounce_delay, function()
    local profile = log.profile_start("CocDiagnosticChanged update")
    NODE_SEVERITIES = from_coc()
    NODE_SEVERITIES_VERSION = NODE_SEVERITIES_VERSION + 1
    if log.enabled("diagnostics") then
      for bufname, severity in pairs(NODE_SEVERITIES) do
        log.line("diagnostics", "COC Indexing bufname '%s' with severity %d", bufname, severity)
      end
    end
    log.profile_end(profile)

    local bufnr = view.get_bufnr()
    local should_draw = bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
    if should_draw then
      local explorer = core.get_explorer()
      if explorer then
        explorer.renderer:draw()
      end
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
  if node:is(DirectoryNode) and not M.show_on_dirs then
    return nil
  end

  -- here, we do a lazy update of the diagnostic status carried by the node.
  -- This is by design, as diagnostics and nodes live in completely separate
  -- worlds, and this module is the link between the two
  if not node.diag_status or node.diag_status.cache_version < NODE_SEVERITIES_VERSION then
    node.diag_status = from_cache(node)
  end

  local dir = node:as(DirectoryNode)

  -- file
  if not dir then
    return node.diag_status
  end

  -- dir is closed or we should show on open_dirs
  if not dir.open or M.show_on_open_dirs then
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
