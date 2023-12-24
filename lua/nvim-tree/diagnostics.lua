local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local log = require "nvim-tree.log"

local M = {}

local severity_levels = {
  Error = 1,
  Warning = 2,
  Information = 3,
  Hint = 4,
}

---@class DiagStatus
---@field value integer|nil
---@field cache_version integer

--- The buffer-severity mappings derived during the last diagnostic list update.
---@type table
local BUFFER_SEVERITY = {}

--- The cache version number of the buffer-severity mappings.
---@type integer
local BUFFER_SEVERITY_VERSION = 0

---@param path string
---@return string
local function uniformize_path(path)
  return utils.canonical_path(path:gsub("\\", "/"))
end

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
        local bufname = uniformize_path(vim.api.nvim_buf_get_name(buf))
        local severity = diagnostic.severity
        local highest_severity = buffer_severity[bufname] or severity
        buffer_severity[bufname] = math.min(highest_severity, severity)
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

  local buffer_severity = {}
  for _, diagnostic in ipairs(diagnostic_list) do
    local bufname = uniformize_path(diagnostic.file)
    local coc_severity = severity_levels[diagnostic.severity]
    local highest_severity = buffer_severity[bufname] or coc_severity
    if is_severity_in_range(highest_severity, M.severity) then
      buffer_severity[bufname] = math.min(highest_severity, coc_severity)
    end
  end

  return buffer_severity
end

local function is_using_coc()
  return vim.g.coc_service_initialized == 1
end

---@param node Node
---@return DiagStatus
local function from_cache(node)
  local nodepath = uniformize_path(node.absolute_path)
  local max_severity = nil
  if not node.nodes then
    -- direct cache hit for files
    max_severity = BUFFER_SEVERITY[nodepath]
  else
    -- dirs should be searched in the list of cached buffer names by prefix
    for bufname, severity in pairs(BUFFER_SEVERITY) do
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
  return { value = max_severity, cache_version = BUFFER_SEVERITY_VERSION }
end

function M.update()
  if not M.enable then
    return
  end
  utils.debounce("diagnostics", M.debounce_delay, function()
    local profile = log.profile_start "diagnostics update"
    if is_using_coc() then
      BUFFER_SEVERITY = from_coc()
    else
      BUFFER_SEVERITY = from_nvim_lsp()
    end
    BUFFER_SEVERITY_VERSION = BUFFER_SEVERITY_VERSION + 1
    log.node("diagnostics", BUFFER_SEVERITY, "update")
    log.profile_end(profile)
    if view.is_buf_valid(view.get_bufnr()) then
      require("nvim-tree.renderer").draw()
    end
  end)
end

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
  if not node.diag_status or node.diag_status.cache_version < BUFFER_SEVERITY_VERSION then
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
