local config = require("nvim-tree.config")

local M = {}

---Create all global autocommands after setup.
---Idempotent: removes existing autocommands first.
---For startup performance reasons, all requires must be done inline during the callback.
---Some short circuiting logic is done directly inside the callback to prevent unnecessary requires.
function M.global()
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
        require("nvim-tree.actions.tree.change-dir").fn(vim.uv.cwd())
      end,
    })
  end

  if config.g.update_focused_file.enable then
    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup_id,
      callback = function(event)
        if type(config.g.update_focused_file.exclude) == "function" and config.g.update_focused_file.exclude(event) then
          return
        end
        require("nvim-tree.utils").debounce("BufEnter:find_file", config.g.view.debounce_delay, function()
          require("nvim-tree.actions.tree.find-file").fn()
        end)
      end,
    })
  end

  if config.g.hijack_directories.enable and (config.g.disable_netrw or config.g.hijack_netrw) then
    vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
      group = augroup_id,
      nested = true,
      callback = function(data)
        local bufname = vim.api.nvim_buf_get_name(data.buf)
        if vim.fn.isdirectory(bufname) == 1 then
          require("nvim-tree.actions.tree.open").open_on_directory(bufname)
        end
      end,
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

  if config.g.renderer.full_name then
    local group = vim.api.nvim_create_augroup("nvim_tree_floating_node", { clear = true })
    vim.api.nvim_create_autocmd({ "BufLeave", "CursorMoved" }, {
      group = group,
      pattern = { "NvimTree_*" },
      callback = function()
        require("nvim-tree.renderer.components.full-name").hide()
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      group = group,
      pattern = { "NvimTree_*" },
      callback = function()
        require("nvim-tree.renderer.components.full-name").show()
      end,
    })
  end
end

return M
