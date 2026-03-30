local config = require("nvim-tree.config")

local M = {}

---`require("nvim-tree").setup` must be called once to initialise nvim-tree.
---
---Call again to apply a change in configuration without restarting Nvim.
---
---See :help nvim-tree-setup
---
---@param config_user? nvim_tree.config subset, uses defaults when nil
function M.setup(config_user)
  local log = require("nvim-tree.log")

  -- Nvim version check
  if vim.fn.has("nvim-0.9") == 0 then
    require("nvim-tree.notify").warn("nvim-tree.lua requires Neovim 0.9 or higher")
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
  require("nvim-tree.appearance").highlight()

  -- set the initial view state based on config
  require("nvim-tree.view-state").initialize()

  -- idempotent au (re)definition
  require("nvim-tree.autocmd").global()

  -- subsequent calls to setup clear all state
  if vim.g.NvimTreeSetup == 1 then
    require("nvim-tree.core").purge_all_state()
  end

  -- hydrate post setup API
  require("nvim-tree.api.impl").hydrate_post_setup(require("nvim-tree.api"))

  vim.g.NvimTreeSetup = 1
  vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeSetup" })
end

vim.g.NvimTreeRequired = 1
vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeRequired" })

return M
