local api = require("nvim-tree.api")
local log = require("nvim-tree.log")
local view = require("nvim-tree.view")
local utils = require("nvim-tree.utils")
local actions = require("nvim-tree.actions")
local core = require("nvim-tree.core")
local notify = require("nvim-tree.notify")
local config = require("nvim-tree.config")

local M = {
  init_root = "",
}

--- Helper function to execute some explorer method safely
---@param fn string # key of explorer
---@param ... any|nil
---@return function|nil
local function explorer_fn(fn, ...)
  local explorer = core.get_explorer()
  if explorer then
    return explorer[fn](explorer, ...)
  end
end

--- Update the tree root to a directory or the directory containing
---@param path string relative or absolute
---@param bufnr number|nil
function M.change_root(path, bufnr)
  -- skip if current file is in ignore_list
  if type(bufnr) == "number" then
    local ft

    if vim.fn.has("nvim-0.10") == 1 then
      ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr }) or ""
    else
      ft = vim.api.nvim_buf_get_option(bufnr, "filetype") or "" ---@diagnostic disable-line: deprecated
    end

    for _, value in pairs(config.g.update_focused_file.update_root.ignore_list) do
      if utils.str_find(path, value) or utils.str_find(ft, value) then
        return
      end
    end
  end

  -- don't find inexistent
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local cwd = core.get_cwd()
  if cwd == nil then
    return
  end

  local vim_cwd = vim.fn.getcwd()

  -- test if in vim_cwd
  if utils.path_relative(path, vim_cwd) ~= path then
    if vim_cwd ~= cwd then
      explorer_fn("change_dir", vim_cwd)
    end
    return
  end
  -- test if in cwd
  if utils.path_relative(path, cwd) ~= path then
    return
  end

  -- otherwise test M.init_root
  if config.g.prefer_startup_root and utils.path_relative(path, M.init_root) ~= path then
    explorer_fn("change_dir", M.init_root)
    return
  end
  -- otherwise root_dirs
  for _, dir in pairs(config.g.root_dirs) do
    dir = vim.fn.fnamemodify(dir, ":p")
    if utils.path_relative(path, dir) ~= path then
      explorer_fn("change_dir", dir)
      return
    end
  end
  -- finally fall back to the folder containing the file
  explorer_fn("change_dir", vim.fn.fnamemodify(path, ":p:h"))
end

function M.tab_enter()
  if view.is_visible({ any_tabpage = true }) then
    local bufname = vim.api.nvim_buf_get_name(0)

    local ft
    if vim.fn.has("nvim-0.10") == 1 then
      ft = vim.api.nvim_get_option_value("filetype", { buf = 0 }) or ""
    else
      ft = vim.api.nvim_buf_get_option(0, "ft") ---@diagnostic disable-line: deprecated
    end

    for _, filter in ipairs(config.g.tab.sync.ignore) do
      if bufname:match(filter) ~= nil or ft:match(filter) ~= nil then
        return
      end
    end
    view.open({ focus_tree = false })

    local explorer = core.get_explorer()
    if explorer then
      explorer.renderer:draw()
    end
  end
end

function M.open_on_directory()
  local should_proceed = config.g.hijack_directories.auto_open or view.is_visible()
  if not should_proceed then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) ~= 1 then
    return
  end


  local explorer = core.get_explorer()
  if not explorer then
    core.init(bufname)
  end

  explorer_fn("force_dirchange", bufname, true, false)
end

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
  local function create_nvim_tree_autocmd(name, custom_opts)
    local default_opts = { group = augroup_id }
    vim.api.nvim_create_autocmd(name, vim.tbl_extend("force", default_opts, custom_opts))
  end

  -- prevent new opened file from opening in the same window as nvim-tree
  create_nvim_tree_autocmd("BufWipeout", {
    pattern = "NvimTree_*",
    callback = function()
      if not utils.is_nvim_tree_buf(0) then
        return
      end
      if config.g.actions.open_file.eject then
        view._prevent_buffer_override()
      else
        view.abandon_current_window()
      end
    end,
  })

  if config.g.tab.sync.open then
    create_nvim_tree_autocmd("TabEnter", { callback = vim.schedule_wrap(M.tab_enter) })
  end
  if config.g.sync_root_with_cwd then
    create_nvim_tree_autocmd("DirChanged", {
      callback = function()
        actions.tree.change_dir.fn(vim.loop.cwd())
      end,
    })
  end
  if config.g.update_focused_file.enable then
    create_nvim_tree_autocmd("BufEnter", {
      callback = function(event)
        local exclude = config.g.update_focused_file.exclude
        if type(exclude) == "function" and exclude(event) then
          return
        end
        utils.debounce("BufEnter:find_file", config.g.view.debounce_delay, function()
          actions.tree.find_file.fn()
        end)
      end,
    })
  end

  if config.g.hijack_directories.enable and (config.g.disable_netrw or config.g.hijack_netrw) then
    create_nvim_tree_autocmd({ "BufEnter", "BufNewFile" }, { callback = M.open_on_directory, nested = true })
  end

  if config.g.view.centralize_selection then
    create_nvim_tree_autocmd("BufEnter", {
      pattern = "NvimTree_*",
      callback = function()
        vim.schedule(function()
          vim.api.nvim_buf_call(0, function()
            local is_term_mode = vim.api.nvim_get_mode().mode == "t"
            if is_term_mode then
              return
            end
            vim.cmd([[norm! zz]])
          end)
        end)
      end,
    })
  end

  if config.g.diagnostics.enable then
    create_nvim_tree_autocmd("DiagnosticChanged", {
      callback = function(ev)
        log.line("diagnostics", "DiagnosticChanged")
        require("nvim-tree.diagnostics").update_lsp(ev)
      end,
    })
    create_nvim_tree_autocmd("User", {
      pattern = "CocDiagnosticChange",
      callback = function()
        log.line("diagnostics", "CocDiagnosticChange")
        require("nvim-tree.diagnostics").update_coc()
      end,
    })
  end

  if config.g.view.float.enable and config.g.view.float.quit_on_focus_loss then
    create_nvim_tree_autocmd("WinLeave", {
      pattern = "NvimTree_*",
      callback = function()
        if utils.is_nvim_tree_buf(0) then
          view.close()
        end
      end,
    })
  end

  -- Handles event dispatch when tree is closed by `:q`
  create_nvim_tree_autocmd("WinClosed", {
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
end

function M.purge_all_state()
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
  if vim.fn.has("nvim-0.9") == 0 then
    notify.warn("nvim-tree.lua requires Neovim 0.9 or higher")
    return
  end

  M.init_root = vim.fn.getcwd()

  config.setup(config_user)

  manage_netrw()

  require("nvim-tree.notify").setup(config.g)
  require("nvim-tree.log").setup(config.g)

  if log.enabled("config") then
    log.line("config", "default config + user")
    log.raw("config", "%s\n", vim.inspect(config.g))
  end

  require("nvim-tree.actions").setup(config.g)
  require("nvim-tree.keymap").setup(config.g)
  require("nvim-tree.appearance").setup()
  require("nvim-tree.diagnostics").setup(config.g)
  require("nvim-tree.explorer"):setup(config.g)
  require("nvim-tree.explorer.watch").setup(config.g)
  require("nvim-tree.git").setup(config.g)
  require("nvim-tree.git.utils").setup(config.g)
  require("nvim-tree.view").setup(config.g)
  require("nvim-tree.lib").setup(config.g)
  require("nvim-tree.renderer.components").setup(config.g)
  require("nvim-tree.buffers").setup(config.g)
  require("nvim-tree.help").setup(config.g)
  require("nvim-tree.watcher").setup(config.g)

  setup_autocommands()

  if vim.g.NvimTreeSetup == 1 then
    -- subsequent calls to setup
    M.purge_all_state()
  end

  vim.g.NvimTreeSetup = 1
  vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeSetup" })

  require("nvim-tree.api.impl.post").hydrate(api)
end

vim.g.NvimTreeRequired = 1
vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeRequired" })

return M
