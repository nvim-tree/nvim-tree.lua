local M = {}

---`require("nvim-tree").setup` must be called once to initialise nvim-tree.
---
---Call again to apply a change in configuration without restarting Nvim.
---
---See :help nvim-tree-setup
---
---@param config_user? nvim_tree.config subset, uses defaults when nil
function M.setup(config_user)
  local api = require("nvim-tree.api")
  local api_impl = require("nvim-tree.api.impl")
  local appearance = require("nvim-tree.appearance")
  local autocmd = require("nvim-tree.autocmd")
  local config = require("nvim-tree.config")
  local log = require("nvim-tree.log")
  local view_state = require("nvim-tree.view-state")

  -- Nvim version check
  if vim.fn.has("nvim-0.10") == 0 then
    require("nvim-tree.notify").warn(
      "nvim-tree.lua requires Nvim >= 0.10. You may use a compat-nvim-0.X tag for earlier Nvim versions, however they will receive no updates or support.")
    return
  end

  -- validate and merge with defaults as config.g
  config.setup(config_user)

  -- optionally create the log file
  log.start()

  -- optionally log the configuration
  if log.enabled("config") then
    log.line("config", "default config + user")
    log.raw("config", "%s\n", vim.inspect(config.g))
  end

  -- idempotent highlight definition
  appearance.highlight()

  -- set the initial view state based on config
  view_state.initialize()

  -- idempotent au (re)definition
  autocmd.global()

  -- subsequent calls to setup clear all state
  if vim.g.NvimTreeSetup == 1 then
    require("nvim-tree.core").purge_all_state()
  end

  -- hydrate post setup API
  api_impl.hydrate_post_setup(api)

  vim.g.NvimTreeSetup = 1
  vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeSetup" })
end

vim.g.NvimTreeRequired = 1
vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeRequired" })

return M
