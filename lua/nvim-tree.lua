local log = require("nvim-tree.log")
local view = require("nvim-tree.view")
local utils = require("nvim-tree.utils")
local actions = require("nvim-tree.actions")
local core = require("nvim-tree.core")
local notify = require("nvim-tree.notify")

local _config = {}

local M = {
  init_root = "",
}

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

    for _, value in pairs(_config.update_focused_file.update_root.ignore_list) do
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
      actions.root.change_dir.fn(vim_cwd)
    end
    return
  end
  -- test if in cwd
  if utils.path_relative(path, cwd) ~= path then
    return
  end

  -- otherwise test M.init_root
  if _config.prefer_startup_root and utils.path_relative(path, M.init_root) ~= path then
    actions.root.change_dir.fn(M.init_root)
    return
  end
  -- otherwise root_dirs
  for _, dir in pairs(_config.root_dirs) do
    dir = vim.fn.fnamemodify(dir, ":p")
    if utils.path_relative(path, dir) ~= path then
      actions.root.change_dir.fn(dir)
      return
    end
  end
  -- finally fall back to the folder containing the file
  actions.root.change_dir.fn(vim.fn.fnamemodify(path, ":p:h"))
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

    for _, filter in ipairs(M.config.tab.sync.ignore) do
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
  local should_proceed = _config.hijack_directories.auto_open or view.is_visible()
  if not should_proceed then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) ~= 1 then
    return
  end

  actions.root.change_dir.force_dirchange(bufname, true)
end

---@return table
function M.get_config()
  return M.config
end

---@param disable_netrw boolean
---@param hijack_netrw boolean
local function manage_netrw(disable_netrw, hijack_netrw)
  if hijack_netrw then
    vim.cmd("silent! autocmd! FileExplorer *")
    vim.cmd("autocmd VimEnter * ++once silent! autocmd! FileExplorer *")
  end
  if disable_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end
end

---@param name string|nil
function M.change_dir(name)
  if name then
    actions.root.change_dir.fn(name)
  end

  if _config.update_focused_file.update_root.enable then
    actions.tree.find_file.fn()
  end
end

---@param opts table
local function setup_autocommands(opts)
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
      if opts.actions.open_file.eject then
        view._prevent_buffer_override()
      else
        view.abandon_current_window()
      end
    end,
  })

  if opts.tab.sync.open then
    create_nvim_tree_autocmd("TabEnter", { callback = vim.schedule_wrap(M.tab_enter) })
  end
  if opts.sync_root_with_cwd then
    create_nvim_tree_autocmd("DirChanged", {
      callback = function()
        M.change_dir(vim.loop.cwd())
      end,
    })
  end
  if opts.update_focused_file.enable then
    create_nvim_tree_autocmd("BufEnter", {
      callback = function(event)
        local exclude = opts.update_focused_file.exclude
        if type(exclude) == "function" and exclude(event) then
          return
        end
        utils.debounce("BufEnter:find_file", opts.view.debounce_delay, function()
          actions.tree.find_file.fn()
        end)
      end,
    })
  end

  if opts.hijack_directories.enable then
    create_nvim_tree_autocmd({ "BufEnter", "BufNewFile" }, { callback = M.open_on_directory, nested = true })
  end

  if opts.view.centralize_selection then
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

  if opts.diagnostics.enable then
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

  if opts.view.float.enable and opts.view.float.quit_on_focus_loss then
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

---@type nvim_tree.Config
local DEFAULT_OPTS = { -- BEGIN_DEFAULT_OPTS
  on_attach = "default",
  hijack_cursor = false,
  auto_reload_on_write = true,
  disable_netrw = false,
  hijack_netrw = true,
  hijack_unnamed_buffer_when_opening = false,
  root_dirs = {},
  prefer_startup_root = false,
  sync_root_with_cwd = false,
  reload_on_bufenter = false,
  respect_buf_cwd = false,
  select_prompts = false,
  sort = {
    sorter = "name",
    folders_first = true,
    files_first = false,
  },
  view = {
    centralize_selection = false,
    cursorline = true,
    cursorlineopt = "both",
    debounce_delay = 15,
    side = "left",
    preserve_window_proportions = false,
    number = false,
    relativenumber = false,
    signcolumn = "yes",
    width = 30,
    float = {
      enable = false,
      quit_on_focus_loss = true,
      open_win_config = {
        relative = "editor",
        border = "rounded",
        width = 30,
        height = 30,
        row = 1,
        col = 1,
      },
    },
  },
  renderer = {
    add_trailing = false,
    group_empty = false,
    full_name = false,
    root_folder_label = ":~:s?$?/..?",
    indent_width = 2,
    special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md" },
    hidden_display = "none",
    symlink_destination = true,
    decorators = { "Git", "Open", "Hidden", "Modified", "Bookmark", "Diagnostics", "Copied", "Cut", },
    highlight_git = "none",
    highlight_diagnostics = "none",
    highlight_opened_files = "none",
    highlight_modified = "none",
    highlight_hidden = "none",
    highlight_bookmarks = "none",
    highlight_clipboard = "name",
    indent_markers = {
      enable = false,
      inline_arrows = true,
      icons = {
        corner = "└",
        edge = "│",
        item = "│",
        bottom = "─",
        none = " ",
      },
    },
    icons = {
      web_devicons = {
        file = {
          enable = true,
          color = true,
        },
        folder = {
          enable = false,
          color = true,
        },
      },
      git_placement = "before",
      modified_placement = "after",
      hidden_placement = "after",
      diagnostics_placement = "signcolumn",
      bookmarks_placement = "signcolumn",
      padding = {
        icon = " ",
        folder_arrow = " ",
      },
      symlink_arrow = " ➛ ",
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
        modified = true,
        hidden = false,
        diagnostics = true,
        bookmarks = true,
      },
      glyphs = {
        default = "",
        symlink = "",
        bookmark = "󰆤",
        modified = "●",
        hidden = "󰜌",
        folder = {
          arrow_closed = "",
          arrow_open = "",
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
          symlink_open = "",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
  hijack_directories = {
    enable = true,
    auto_open = true,
  },
  update_focused_file = {
    enable = false,
    update_root = {
      enable = false,
      ignore_list = {},
    },
    exclude = false,
  },
  system_open = {
    cmd = "",
    args = {},
  },
  git = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = true,
    disable_for_dirs = {},
    timeout = 400,
    cygwin_support = false,
  },
  diagnostics = {
    enable = false,
    show_on_dirs = false,
    show_on_open_dirs = true,
    debounce_delay = 500,
    severity = {
      min = vim.diagnostic.severity.HINT,
      max = vim.diagnostic.severity.ERROR,
    },
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
    diagnostic_opts = false,
  },
  modified = {
    enable = false,
    show_on_dirs = true,
    show_on_open_dirs = true,
  },
  filters = {
    enable = true,
    git_ignored = true,
    dotfiles = false,
    git_clean = false,
    no_buffer = false,
    no_bookmark = false,
    custom = {},
    exclude = {},
  },
  live_filter = {
    prefix = "[FILTER]: ",
    always_show_folders = true,
  },
  filesystem_watchers = {
    enable = true,
    debounce_delay = 50,
    ignore_dirs = {
      "/.ccls-cache",
      "/build",
      "/node_modules",
      "/target",
    },
  },
  actions = {
    use_system_clipboard = true,
    change_dir = {
      enable = true,
      global = false,
      restrict_above_cwd = false,
    },
    expand_all = {
      max_folder_discovery = 300,
      exclude = {},
    },
    file_popup = {
      open_win_config = {
        col = 1,
        row = 1,
        relative = "cursor",
        border = "shadow",
        style = "minimal",
      },
    },
    open_file = {
      quit_on_open = false,
      eject = true,
      resize_window = true,
      relative_path = true,
      window_picker = {
        enable = true,
        picker = "default",
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
        exclude = {
          filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
          buftype = { "nofile", "terminal", "help" },
        },
      },
    },
    remove_file = {
      close_window = true,
    },
  },
  trash = {
    cmd = "gio trash",
  },
  tab = {
    sync = {
      open = false,
      close = false,
      ignore = {},
    },
  },
  notify = {
    threshold = vim.log.levels.INFO,
    absolute_path = true,
  },
  help = {
    sort_by = "key",
  },
  ui = {
    confirm = {
      remove = true,
      trash = true,
      default_yes = false,
    },
  },
  bookmarks = {
    persist = false,
  },
  experimental = {
  },
  log = {
    enable = false,
    truncate = false,
    types = {
      all = false,
      config = false,
      copy_paste = false,
      dev = false,
      diagnostics = false,
      git = false,
      profile = false,
      watcher = false,
    },
  },
}-- END_DEFAULT_OPTS

local function merge_options(conf)
  return vim.tbl_deep_extend("force", DEFAULT_OPTS, conf or {})
end

local FIELD_SKIP_VALIDATE = {
  open_win_config = true,
}

local ACCEPTED_TYPES = {
  on_attach = { "function", "string" },
  sort = {
    sorter = { "function", "string" },
  },
  view = {
    width = {
      "string",
      "function",
      "number",
      "table",
      min = { "string", "function", "number" },
      max = { "string", "function", "number" },
      lines_excluded = { "table" },
      padding = { "function", "number" },
    },
  },
  renderer = {
    hidden_display = { "function", "string" },
    group_empty = { "boolean", "function" },
    root_folder_label = { "function", "string", "boolean" },
  },
  update_focused_file = {
    exclude = { "function" },
  },
  git = {
    disable_for_dirs = { "function" },
  },
  filters = {
    custom = { "function" },
  },
  filesystem_watchers = {
    ignore_dirs = { "function" },
  },
  actions = {
    open_file = {
      window_picker = {
        picker = { "function", "string" },
      },
    },
  },
  bookmarks = {
    persist = { "boolean", "string" },
  },
}

local ACCEPTED_STRINGS = {
  sort = {
    sorter = { "name", "case_sensitive", "modification_time", "extension", "suffix", "filetype" },
  },
  view = {
    side = { "left", "right" },
    signcolumn = { "yes", "no", "auto" },
  },
  renderer = {
    hidden_display = { "none", "simple", "all" },
    highlight_git = { "none", "icon", "name", "all" },
    highlight_opened_files = { "none", "icon", "name", "all" },
    highlight_modified = { "none", "icon", "name", "all" },
    highlight_hidden = { "none", "icon", "name", "all" },
    highlight_bookmarks = { "none", "icon", "name", "all" },
    highlight_diagnostics = { "none", "icon", "name", "all" },
    highlight_clipboard = { "none", "icon", "name", "all" },
    icons = {
      git_placement = { "before", "after", "signcolumn", "right_align" },
      modified_placement = { "before", "after", "signcolumn", "right_align" },
      hidden_placement = { "before", "after", "signcolumn", "right_align" },
      diagnostics_placement = { "before", "after", "signcolumn", "right_align" },
      bookmarks_placement = { "before", "after", "signcolumn", "right_align" },
    },
  },
  help = {
    sort_by = { "key", "desc" },
  },
}

local ACCEPTED_ENUMS = {
  view = {
    width = {
      lines_excluded = { "root", },
    },
  },
}

---@param conf? nvim_tree.Config
local function validate_options(conf)
  local msg

  ---@param user any
  ---@param def any
  ---@param strs table
  ---@param types table
  ---@param enums table
  ---@param prefix string
  local function validate(user, def, strs, types, enums, prefix)
    -- if user's option is not a table there is nothing to do
    if type(user) ~= "table" then
      return
    end

    -- we have hit a leaf enum to validate against - it's an integer indexed table
    local enum_value = type(enums) == "table" and next(enums) and type(next(enums)) == "number"

    -- only compare tables with contents that are not integer indexed nor enums
    if not enum_value and (type(def) ~= "table" or not next(def) or type(next(def)) == "number") then
      -- unless the field can be a table (and is not a table in default config)
      if vim.tbl_contains(types, "table") then
        -- use a dummy default to allow all checks
        def = {}
      else
        return
      end
    end

    for k, v in pairs(user) do
      if not FIELD_SKIP_VALIDATE[k] then
        local invalid

        if enum_value then
          if not vim.tbl_contains(enums, v) then
            invalid = string.format("Invalid value for field %s%s: Expected one of enum '%s', got '%s'", prefix, k,
              table.concat(enums, "'|'"), tostring(v))
          end
        else
          if def[k] == nil and types[k] == nil then
            -- option does not exist
            invalid = string.format("Unknown option: %s%s", prefix, k)
          elseif type(v) ~= type(def[k]) then
            local expected

            if types[k] and #types[k] > 0 then
              if not vim.tbl_contains(types[k], type(v)) then
                expected = table.concat(types[k], "|")
              end
            else
              expected = type(def[k])
            end

            if expected then
              -- option is of the wrong type
              invalid = string.format("Invalid option: %s%s. Expected %s, got %s", prefix, k, expected, type(v))
            end
          elseif type(v) == "string" and strs[k] and not vim.tbl_contains(strs[k], v) then
            -- option has type `string` but value is not accepted
            invalid = string.format("Invalid value for field %s%s: '%s'", prefix, k, v)
          end
        end

        if invalid then
          if msg then
            msg = string.format("%s\n%s", msg, invalid)
          else
            msg = invalid
          end
          user[k] = nil
        elseif not enum_value then
          validate(v, def[k], strs[k] or {}, types[k] or {}, enums[k] or {}, prefix .. k .. ".")
        end
      end
    end
  end

  validate(conf, DEFAULT_OPTS, ACCEPTED_STRINGS, ACCEPTED_TYPES, ACCEPTED_ENUMS, "")

  if msg then
    notify.warn(msg .. "\n\nsee :help nvim-tree-opts for available configuration options")
  end
end

--- Apply OS specific localisations to DEFAULT_OPTS
local function localise_default_opts()
  if utils.is_macos or utils.is_windows then
    DEFAULT_OPTS.trash.cmd = "trash"
  end
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

---@param conf? nvim_tree.Config
function M.setup(conf)
  if vim.fn.has("nvim-0.9") == 0 then
    notify.warn("nvim-tree.lua requires Neovim 0.9 or higher")
    return
  end

  M.init_root = vim.fn.getcwd()

  localise_default_opts()

  require("nvim-tree.legacy").migrate_legacy_options(conf or {})

  validate_options(conf)

  local opts = merge_options(conf)

  local netrw_disabled = opts.disable_netrw or opts.hijack_netrw

  _config.root_dirs = opts.root_dirs
  _config.prefer_startup_root = opts.prefer_startup_root
  _config.update_focused_file = opts.update_focused_file
  _config.hijack_directories = opts.hijack_directories
  _config.hijack_directories.enable = _config.hijack_directories.enable and netrw_disabled

  manage_netrw(opts.disable_netrw, opts.hijack_netrw)

  M.config = opts
  require("nvim-tree.notify").setup(opts)
  require("nvim-tree.log").setup(opts)

  if log.enabled("config") then
    log.line("config", "default config + user")
    log.raw("config", "%s\n", vim.inspect(opts))
  end

  require("nvim-tree.actions").setup(opts)
  require("nvim-tree.keymap").setup(opts)
  require("nvim-tree.appearance").setup()
  require("nvim-tree.diagnostics").setup(opts)
  require("nvim-tree.explorer"):setup(opts)
  require("nvim-tree.explorer.watch").setup(opts)
  require("nvim-tree.git").setup(opts)
  require("nvim-tree.git.utils").setup(opts)
  require("nvim-tree.view").setup(opts)
  require("nvim-tree.lib").setup(opts)
  require("nvim-tree.renderer.components").setup(opts)
  require("nvim-tree.buffers").setup(opts)
  require("nvim-tree.help").setup(opts)
  require("nvim-tree.watcher").setup(opts)

  setup_autocommands(opts)

  if vim.g.NvimTreeSetup == 1 then
    -- subsequent calls to setup
    M.purge_all_state()
  end

  vim.g.NvimTreeSetup = 1
  vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeSetup" })
end

vim.g.NvimTreeRequired = 1
vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeRequired" })

return M
