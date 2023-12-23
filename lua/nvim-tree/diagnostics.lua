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

--- A dictionary tree containing buffer-severity mappings.
---@type table
local buffer_severity_dict = {}

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

function M.update()
  if not M.enable then
    return
  end
  utils.debounce("diagnostics", M.debounce_delay, function()
    local profile = log.profile_start "diagnostics update"
    if is_using_coc() then
      buffer_severity_dict = from_coc()
    else
      buffer_severity_dict = from_nvim_lsp()
    end
    log.node("diagnostics", buffer_severity_dict, "update")
    log.profile_end(profile)
    if view.is_buf_valid(view.get_bufnr()) then
      require("nvim-tree.renderer").draw()
    end
  end)
end

---@param node Node
function M.update_node_severity_level(node)
  if not M.enable then
    return
  end

  local is_folder = node.nodes ~= nil
  local nodepath = uniformize_path(node.absolute_path)

  if is_folder then
    local max_severity = nil
    if M.show_on_dirs and (not node.open or M.show_on_open_dirs) then
      for bufname, severity in pairs(buffer_severity_dict) do
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
    node.diag_status = max_severity
  else
    node.diag_status = buffer_severity_dict[nodepath]
  end
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
