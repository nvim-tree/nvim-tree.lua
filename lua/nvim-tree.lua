local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local colors = require "nvim-tree.colors"
local renderer = require "nvim-tree.renderer"
local view = require "nvim-tree.view"
local commands = require "nvim-tree.commands"
local utils = require "nvim-tree.utils"
local change_dir = require "nvim-tree.actions.root.change-dir"
local legacy = require "nvim-tree.legacy"
local core = require "nvim-tree.core"
local reloaders = require "nvim-tree.actions.reloaders.reloaders"
local git = require "nvim-tree.git"
local filters = require "nvim-tree.explorer.filters"
local modified = require "nvim-tree.modified"
local notify = require "nvim-tree.notify"
local keymap_legacy = require "nvim-tree.keymap-legacy"
local find_file = require "nvim-tree.actions.tree.find-file"
local open = require "nvim-tree.actions.tree.open"

local _config = {}

local M = {
  setup_called = false,
  init_root = "",
}

function M.focus()
  open.fn()
  view.focus()
end

--- Update the tree root to a directory or the directory containing
--- @param path string relative or absolute
--- @param bufnr number|nil
function M.change_root(path, bufnr)
  -- skip if current file is in ignore_list
  if type(bufnr) == "number" then
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype") or ""
    for _, value in pairs(_config.update_focused_file.ignore_list) do
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
  local vim_cwd = vim.fn.getcwd()

  -- test if in vim_cwd
  if utils.path_relative(path, vim_cwd) ~= path then
    if vim_cwd ~= cwd then
      change_dir.fn(vim_cwd)
    end
    return
  end
  -- test if in cwd
  if utils.path_relative(path, cwd) ~= path then
    return
  end

  -- otherwise test M.init_root
  if _config.prefer_startup_root and utils.path_relative(path, M.init_root) ~= path then
    change_dir.fn(M.init_root)
    return
  end
  -- otherwise root_dirs
  for _, dir in pairs(_config.root_dirs) do
    dir = vim.fn.fnamemodify(dir, ":p")
    if utils.path_relative(path, dir) ~= path then
      change_dir.fn(dir)
      return
    end
  end
  -- finally fall back to the folder containing the file
  change_dir.fn(vim.fn.fnamemodify(path, ":p:h"))
end

function M.open_replacing_current_buffer(cwd)
  if view.is_visible() then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if bufname == "" or vim.loop.fs_stat(bufname) == nil then
    return
  end

  if cwd == "" or cwd == nil then
    cwd = vim.fn.fnamemodify(bufname, ":p:h")
  end

  if not core.get_explorer() or cwd ~= core.get_cwd() then
    core.init(cwd)
  end
  view.open_in_current_win { hijack_current_buf = false, resize = false }
  require("nvim-tree.renderer").draw()
  require("nvim-tree.actions.finders.find-file").fn(bufname)
end

function M.tab_enter()
  if view.is_visible { any_tabpage = true } then
    local bufname = vim.api.nvim_buf_get_name(0)
    local ft = vim.api.nvim_buf_get_option(0, "ft")
    for _, filter in ipairs(M.config.tab.sync.ignore) do
      if bufname:match(filter) ~= nil or ft:match(filter) ~= nil then
        return
      end
    end
    view.open { focus_tree = false }
    require("nvim-tree.renderer").draw()
  end
end

local function find_existing_windows()
  return vim.tbl_filter(function(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_buf_get_name(buf):match "NvimTree" ~= nil
  end, vim.api.nvim_list_wins())
end

function M.open_on_directory()
  local should_proceed = M.initialized and (_config.hijack_directories.auto_open or view.is_visible())
  if not should_proceed then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) ~= 1 then
    return
  end

  change_dir.force_dirchange(bufname, true)
end

function M.reset_highlight()
  colors.setup()
  view.reset_winhl()
  renderer.render_hl(view.get_bufnr())
end

local prev_line
function M.place_cursor_on_node()
  local l = vim.api.nvim_win_get_cursor(0)[1]
  if l == prev_line then
    return
  end
  prev_line = l

  local node = lib.get_node_at_cursor()
  if not node or node.name == ".." then
    return
  end

  local line = vim.api.nvim_get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local idx = vim.fn.stridx(line, node.name)

  if idx >= 0 then
    vim.api.nvim_win_set_cursor(0, { cursor[1], idx })
  end
end

function M.on_enter(netrw_disabled)
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local ft_ignore = _config.ignore_ft_on_setup

  local stats = vim.loop.fs_stat(bufname)
  local is_dir = stats and stats.type == "directory"
  local is_file = stats and stats.type == "file"

  local lines = not is_dir and vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) or {}
  local buf_has_content = #lines > 1 or (#lines == 1 and lines[1] ~= "")

  local buf_is_dir = is_dir and netrw_disabled
  local buf_is_empty = bufname == "" and not buf_has_content
  local should_be_preserved = vim.tbl_contains(ft_ignore, buftype)

  local should_open = false
  local should_focus_other_window = false
  local should_find = false
  if (_config.open_on_setup or _config.open_on_setup_file) and not should_be_preserved then
    if buf_is_dir or buf_is_empty then
      should_open = true
    elseif is_file and _config.open_on_setup_file then
      should_open = true
      should_focus_other_window = true
      should_find = _config.update_focused_file.enable
    elseif _config.ignore_buffer_on_setup then
      should_open = true
      should_focus_other_window = true
    end
  end

  local should_hijack = _config.hijack_directories.enable
    and _config.hijack_directories.auto_open
    and is_dir
    and not should_be_preserved

  -- Session that left a NvimTree Buffer opened, reopen with it
  local existing_tree_wins = find_existing_windows()
  if existing_tree_wins[1] then
    vim.api.nvim_set_current_win(existing_tree_wins[1])
  end

  if should_open or should_hijack or existing_tree_wins[1] ~= nil then
    local cwd
    if is_dir then
      cwd = vim.fn.expand(vim.fn.fnameescape(bufname))
      -- INFO: could potentially conflict with rooter plugins
      vim.cmd("noautocmd cd " .. vim.fn.fnameescape(cwd))
    end

    lib.open { path = cwd }

    if should_focus_other_window then
      vim.cmd "noautocmd wincmd p"
      if should_find then
        find_file.fn()
      end
    end
  end
  M.initialized = true
end

function M.get_config()
  return M.config
end

local function manage_netrw(disable_netrw, hijack_netrw)
  if hijack_netrw then
    vim.cmd "silent! autocmd! FileExplorer *"
    vim.cmd "autocmd VimEnter * ++once silent! autocmd! FileExplorer *"
  end
  if disable_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end
end

function M.change_dir(name)
  change_dir.fn(name)

  if _config.update_focused_file.enable then
    find_file.fn()
  end
end

local function setup_autocommands(opts)
  local augroup_id = vim.api.nvim_create_augroup("NvimTree", { clear = true })
  local function create_nvim_tree_autocmd(name, custom_opts)
    local default_opts = { group = augroup_id }
    vim.api.nvim_create_autocmd(name, vim.tbl_extend("force", default_opts, custom_opts))
  end

  -- reset highlights when colorscheme is changed
  create_nvim_tree_autocmd("ColorScheme", { callback = M.reset_highlight })

  -- prevent new opened file from opening in the same window as nvim-tree
  create_nvim_tree_autocmd("BufWipeout", {
    pattern = "NvimTree_*",
    callback = function()
      if utils.is_nvim_tree_buf(0) then
        view._prevent_buffer_override()
      end
    end,
  })

  local has_watchers = opts.filesystem_watchers.enable

  if opts.auto_reload_on_write and not has_watchers then
    create_nvim_tree_autocmd("BufWritePost", { callback = reloaders.reload_explorer })
  end

  create_nvim_tree_autocmd("BufReadPost", {
    callback = function(data)
      -- update opened file buffers
      if
        (filters.config.filter_no_buffer or renderer.config.highlight_opened_files ~= "none")
        and vim.bo[data.buf].buftype == ""
      then
        utils.debounce("Buf:filter_buffer", opts.view.debounce_delay, function()
          reloaders.reload_explorer()
        end)
      end
    end,
  })

  create_nvim_tree_autocmd("BufUnload", {
    callback = function(data)
      -- update opened file buffers
      if
        (filters.config.filter_no_buffer or renderer.config.highlight_opened_files ~= "none")
        and vim.bo[data.buf].buftype == ""
      then
        utils.debounce("Buf:filter_buffer", opts.view.debounce_delay, function()
          reloaders.reload_explorer(nil, data.buf)
        end)
      end
    end,
  })

  if not has_watchers and opts.git.enable then
    create_nvim_tree_autocmd("User", {
      pattern = { "FugitiveChanged", "NeogitStatusRefreshed" },
      callback = reloaders.reload_git,
    })
  end

  if opts.tab.sync.open then
    create_nvim_tree_autocmd("TabEnter", { callback = vim.schedule_wrap(M.tab_enter) })
  end
  if opts.hijack_cursor then
    create_nvim_tree_autocmd("CursorMoved", {
      pattern = "NvimTree_*",
      callback = function()
        if utils.is_nvim_tree_buf(0) then
          M.place_cursor_on_node()
        end
      end,
    })
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
      callback = function()
        utils.debounce("BufEnter:find_file", opts.view.debounce_delay, function()
          find_file.fn()
        end)
      end,
    })
  end

  if opts.hijack_directories.enable then
    create_nvim_tree_autocmd({ "BufEnter", "BufNewFile" }, { callback = M.open_on_directory })
  end

  if opts.reload_on_bufenter and not has_watchers then
    create_nvim_tree_autocmd("BufEnter", {
      pattern = "NvimTree_*",
      callback = function()
        if utils.is_nvim_tree_buf(0) then
          reloaders.reload_explorer()
        end
      end,
    })
  end

  if opts.view.centralize_selection then
    create_nvim_tree_autocmd("BufEnter", {
      pattern = "NvimTree_*",
      callback = function()
        vim.schedule(function()
          vim.api.nvim_buf_call(0, function()
            vim.cmd [[norm! zz]]
          end)
        end)
      end,
    })
  end

  if opts.diagnostics.enable then
    create_nvim_tree_autocmd("DiagnosticChanged", {
      callback = function()
        log.line("diagnostics", "DiagnosticChanged")
        require("nvim-tree.diagnostics").update()
      end,
    })
    create_nvim_tree_autocmd("User", {
      pattern = "CocDiagnosticChange",
      callback = function()
        log.line("diagnostics", "CocDiagnosticChange")
        require("nvim-tree.diagnostics").update()
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

  if opts.modified.enable then
    create_nvim_tree_autocmd({ "BufModifiedSet", "BufWritePost" }, {
      callback = function()
        utils.debounce("Buf:modified", opts.view.debounce_delay, function()
          modified.reload()
          reloaders.reload_explorer()
        end)
      end,
    })
  end
end

local DEFAULT_OPTS = { -- BEGIN_DEFAULT_OPTS
  auto_reload_on_write = true,
  disable_netrw = false,
  hijack_cursor = false,
  hijack_netrw = true,
  hijack_unnamed_buffer_when_opening = false,
  ignore_buffer_on_setup = false,
  open_on_setup = false,
  open_on_setup_file = false,
  sort_by = "name",
  root_dirs = {},
  prefer_startup_root = false,
  sync_root_with_cwd = false,
  reload_on_bufenter = false,
  respect_buf_cwd = false,
  on_attach = "default",
  remove_keymaps = false,
  select_prompts = false,
  view = {
    centralize_selection = false,
    cursorline = true,
    debounce_delay = 15,
    width = 30,
    hide_root_folder = false,
    side = "left",
    preserve_window_proportions = false,
    number = false,
    relativenumber = false,
    signcolumn = "yes",
    mappings = {
      custom_only = false,
      list = {
        -- user mappings go here
      },
    },
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
    highlight_git = false,
    full_name = false,
    highlight_opened_files = "none",
    highlight_modified = "none",
    root_folder_label = ":~:s?$?/..?",
    indent_width = 2,
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
      webdev_colors = true,
      git_placement = "before",
      modified_placement = "after",
      padding = " ",
      symlink_arrow = " ➛ ",
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
        modified = true,
      },
      glyphs = {
        default = "",
        symlink = "",
        bookmark = "",
        modified = "●",
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
    special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md" },
    symlink_destination = true,
  },
  hijack_directories = {
    enable = true,
    auto_open = true,
  },
  update_focused_file = {
    enable = false,
    update_root = false,
    ignore_list = {},
  },
  ignore_ft_on_setup = {},
  system_open = {
    cmd = "",
    args = {},
  },
  diagnostics = {
    enable = false,
    show_on_dirs = false,
    show_on_open_dirs = true,
    debounce_delay = 50,
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
  },
  filters = {
    dotfiles = false,
    git_clean = false,
    no_buffer = false,
    custom = {},
    exclude = {},
  },
  filesystem_watchers = {
    enable = true,
    debounce_delay = 50,
    ignore_dirs = {},
  },
  git = {
    enable = true,
    ignore = true,
    show_on_dirs = true,
    show_on_open_dirs = true,
    timeout = 400,
  },
  modified = {
    enable = false,
    show_on_dirs = true,
    show_on_open_dirs = true,
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
      resize_window = true,
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
  live_filter = {
    prefix = "[FILTER]: ",
    always_show_folders = true,
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
  },
  ui = {
    confirm = {
      remove = true,
      trash = true,
    },
  },
  experimental = {
    git = {
      async = false,
    },
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
} -- END_DEFAULT_OPTS

local function merge_options(conf)
  return vim.tbl_deep_extend("force", DEFAULT_OPTS, conf or {})
end

local FIELD_SKIP_VALIDATE = {
  open_win_config = true,
}

local FIELD_OVERRIDE_TYPECHECK = {
  width = { string = true, ["function"] = true, number = true, ["table"] = true },
  max = { string = true, ["function"] = true, number = true },
  min = { string = true, ["function"] = true, number = true },
  remove_keymaps = { boolean = true, table = true },
  on_attach = { ["function"] = true, string = true },
  sort_by = { ["function"] = true, string = true },
  root_folder_label = { ["function"] = true, string = true },
  picker = { ["function"] = true, string = true },
}

local function validate_options(conf)
  local msg

  local function validate(user, def, prefix)
    -- only compare tables with contents that are not integer indexed
    if type(user) ~= "table" or type(def) ~= "table" or not next(def) or type(next(def)) == "number" then
      return
    end

    for k, v in pairs(user) do
      if not FIELD_SKIP_VALIDATE[k] then
        local invalid
        local override_typecheck = FIELD_OVERRIDE_TYPECHECK[k] or {}
        if def[k] == nil then
          -- option does not exist
          invalid = string.format("[NvimTree] unknown option: %s%s", prefix, k)
        elseif type(v) ~= type(def[k]) and not override_typecheck[type(v)] then
          -- option is of the wrong type and is not a function
          invalid =
            string.format("[NvimTree] invalid option: %s%s expected: %s actual: %s", prefix, k, type(def[k]), type(v))
        end

        if invalid then
          if msg then
            msg = string.format("%s | %s", msg, invalid)
          else
            msg = string.format("%s", invalid)
          end
          user[k] = nil
        else
          validate(v, def[k], prefix .. k .. ".")
        end
      end
    end
  end

  validate(conf, DEFAULT_OPTS, "")

  if msg then
    vim.notify_once(msg .. " | see :help nvim-tree-setup for available configuration options", vim.log.levels.WARN)
  end
end

function M.setup(conf)
  if vim.fn.has "nvim-0.8" == 0 then
    vim.notify_once("nvim-tree.lua requires Neovim 0.8 or higher", vim.log.levels.WARN)
    return
  end

  M.init_root = vim.fn.getcwd()

  legacy.migrate_legacy_options(conf or {})

  validate_options(conf)

  local opts = merge_options(conf)

  local netrw_disabled = opts.disable_netrw or opts.hijack_netrw

  _config.root_dirs = opts.root_dirs
  _config.prefer_startup_root = opts.prefer_startup_root
  _config.update_focused_file = opts.update_focused_file
  _config.open_on_setup = opts.open_on_setup
  _config.open_on_setup_file = opts.open_on_setup_file
  _config.ignore_buffer_on_setup = opts.ignore_buffer_on_setup
  _config.ignore_ft_on_setup = opts.ignore_ft_on_setup
  _config.hijack_directories = opts.hijack_directories
  _config.hijack_directories.enable = _config.hijack_directories.enable and netrw_disabled

  manage_netrw(opts.disable_netrw, opts.hijack_netrw)

  M.config = opts
  require("nvim-tree.notify").setup(opts)
  require("nvim-tree.log").setup(opts)

  if log.enabled "config" then
    log.line("config", "default config + user")
    log.raw("config", "%s\n", vim.inspect(opts))
  end

  keymap_legacy.generate_legacy_on_attach(opts)

  require("nvim-tree.actions").setup(opts)
  require("nvim-tree.keymap").setup(opts)
  require("nvim-tree.colors").setup()
  require("nvim-tree.diagnostics").setup(opts)
  require("nvim-tree.explorer").setup(opts)
  require("nvim-tree.git").setup(opts)
  require("nvim-tree.git.runner").setup(opts)
  require("nvim-tree.view").setup(opts)
  require("nvim-tree.lib").setup(opts)
  require("nvim-tree.renderer").setup(opts)
  require("nvim-tree.live-filter").setup(opts)
  require("nvim-tree.marks").setup(opts)
  require("nvim-tree.modified").setup(opts)
  if M.config.renderer.icons.show.file and pcall(require, "nvim-web-devicons") then
    require("nvim-web-devicons").setup()
  end

  setup_autocommands(opts)

  if not M.setup_called then
    -- first call to setup
    commands.setup()
  else
    -- subsequent calls to setup
    require("nvim-tree.watcher").purge_watchers()
    view.close_all_tabs()
    view.abandon_all_windows()
    if core.get_explorer() ~= nil then
      git.purge_state()
      TreeExplorer = nil
    end
  end

  M.setup_called = true

  vim.schedule(function()
    if
      #opts.ignore_ft_on_setup > 0
      or opts.open_on_setup == true
      or opts.open_on_setup_file
      or opts.ignore_buffer_on_setup
    then
      notify.info "open_on_setup behaviour has been deprecated, please see https://github.com/nvim-tree/nvim-tree.lua/wiki/Open-At-Startup"
      M.on_enter(netrw_disabled)
    else
      M.initialized = true
    end
    vim.g.NvimTreeSetup = 1
    vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeSetup" })
  end)
end

vim.g.NvimTreeRequired = 1
vim.api.nvim_exec_autocmds("User", { pattern = "NvimTreeRequired" })

return M
