local config = require("nvim-tree.config")

local M = {}

local function manage_netrw()
  if config.g.hijack_netrw then
    vim.cmd("silent! autocmd! FileExplorer *")
    vim.cmd("autocmd VimEnter * ++once silent! autocmd! FileExplorer *")
  end
  if config.g.disable_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end
end

local function setup_autocommands()
  local augroup_id = vim.api.nvim_create_augroup("NvimTree", { clear = true })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup_id,
    pattern = "NvimTree_*",
    callback = function()
      require("nvim-tree.view").wipeout()
    end,
  })

  if config.g.tab.sync.open then
    vim.api.nvim_create_autocmd("TabEnter", {
      group = augroup_id,
      callback = vim.schedule_wrap(function()
        require("nvim-tree.actions.tree.open").tab_enter()
      end)
    })
  end

  if config.g.sync_root_with_cwd then
    vim.api.nvim_create_autocmd("DirChanged", {
      group = augroup_id,
      callback = function()
        require("nvim-tree.actions.tree.change-dir").fn(vim.loop.cwd())
      end,
    })
  end

  if config.g.update_focused_file.enable then
    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup_id,
      callback = function(event)
        require("nvim-tree.actions.tree.find-file").buf_enter(event)
      end,
    })
  end

  if config.g.hijack_directories.enable and (config.g.disable_netrw or config.g.hijack_netrw) then
    vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
      group = augroup_id,
      callback = function()
        require("nvim-tree.actions.tree.open").open_on_directory()
      end,
      nested = true
    })
  end

  if config.g.view.centralize_selection then
    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup_id,
      pattern = "NvimTree_*",
      callback = vim.schedule_wrap(function()
        vim.api.nvim_buf_call(0, function()
          local is_term_mode = vim.api.nvim_get_mode().mode == "t"
          if is_term_mode then
            return
          end
          vim.cmd([[norm! zz]])
        end)
      end)
    })
  end

  if config.g.diagnostics.enable then
    vim.api.nvim_create_autocmd("DiagnosticChanged", {
      group = augroup_id,
      callback = function(ev)
        require("nvim-tree.diagnostics").update_lsp(ev)
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      group = augroup_id,
      pattern = "CocDiagnosticChange",
      callback = function()
        require("nvim-tree.diagnostics").update_coc()
      end,
    })
  end

  if config.g.view.float.enable and config.g.view.float.quit_on_focus_loss then
    vim.api.nvim_create_autocmd("WinLeave", {
      group = augroup_id,
      pattern = "NvimTree_*",
      callback = function()
        if require("nvim-tree.utils").is_nvim_tree_buf(0) then
          require("nvim-tree.view").close()
        end
      end,
    })
  end

  -- Handles event dispatch when tree is closed by `:q`
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup_id,
    pattern = "*",
    ---@param ev vim.api.keyset.create_autocmd.callback_args
    callback = function(ev)
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      if vim.api.nvim_get_option_value("filetype", { buf = ev.buf }) == "NvimTree" then
        require("nvim-tree.events")._dispatch_on_tree_close()
      end
    end,
  })

  -- renderer.full name
  require("nvim-tree.renderer.components.full-name").setup_autocommands()
end

function M.purge_all_state()
  local view = require("nvim-tree.view")
  local core = require("nvim-tree.core")

  view.close_all_tabs()
  view.abandon_all_windows()
  local explorer = core.get_explorer()
  if explorer then
    require("nvim-tree.git").purge_state()
    explorer:destroy()
    core.reset_explorer()
  end
  -- purge orphaned that were not destroyed by their nodes
  require("nvim-tree.watcher").purge_watchers()
end

---@param config_user? nvim_tree.config user supplied subset of config
function M.setup(config_user)
  local log = require("nvim-tree.log")

  if vim.fn.has("nvim-0.9") == 0 then
    require("nvim-tree.notify").warn("nvim-tree.lua requires Neovim 0.9 or higher")
    return
  end

  config.setup(config_user)

  manage_netrw()

  require("nvim-tree.log").start()

  if log.enabled("config") then
    log.line("config", "default config + user")
    log.raw("config", "%s\n", vim.inspect(config.g))
  end

  require("nvim-tree.appearance").set_hl()

  setup_autocommands()

  if vim.g.NvimTreeSetup == 1 then
    -- subsequent calls to setup
    M.purge_all_state()
  end

  vim.g.NvimTreeSetup = 1
  vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeSetup" })

  require("nvim-tree.api.impl").hydrate_post_setup(require("nvim-tree.api"))
end

vim.g.NvimTreeRequired = 1
vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeRequired" })

return M
