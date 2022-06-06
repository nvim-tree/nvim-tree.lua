local luv = vim.loop
local api = vim.api

local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local colors = require "nvim-tree.colors"
local renderer = require "nvim-tree.renderer"
local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local change_dir = require "nvim-tree.actions.change-dir"
local legacy = require "nvim-tree.legacy"
local core = require "nvim-tree.core"
local reloaders = require "nvim-tree.actions.reloaders"
local copy_paste = require "nvim-tree.actions.copy-paste"
local collapse_all = require "nvim-tree.actions.collapse-all"

local _config = {}

local M = {
  setup_called = false,
}

function M.focus()
  M.open()
  view.focus()
end

---@deprecated
M.on_keypress = require("nvim-tree.actions").on_keypress

function M.toggle(find_file, no_focus, cwd)
  if view.is_visible() then
    view.close()
  else
    local previous_buf = api.nvim_get_current_buf()
    M.open(cwd)
    if _config.update_focused_file.enable or find_file then
      M.find_file(false, previous_buf)
    end
    if no_focus then
      vim.cmd "noautocmd wincmd p"
    end
  end
end

function M.open(cwd)
  cwd = cwd ~= "" and cwd or nil
  if view.is_visible() then
    lib.set_target_win()
    view.focus()
  else
    lib.open(cwd)
  end
end

function M.open_replacing_current_buffer()
  if view.is_visible() then
    return
  end

  local buf = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(buf)
  if bufname == "" or vim.loop.fs_stat(bufname) == nil then
    return
  end

  local cwd = vim.fn.fnamemodify(bufname, ":p:h")
  if not core.get_explorer() or cwd ~= core.get_cwd() then
    core.init(cwd)
  end
  view.open_in_current_win { hijack_current_buf = false, resize = false }
  require("nvim-tree.renderer").draw()
  require("nvim-tree.actions.find-file").fn(bufname)
end

function M.tab_change()
  if view.is_visible { any_tabpage = true } then
    local bufname = api.nvim_buf_get_name(0)
    if bufname:match "Neogit" ~= nil or bufname:match "--graph" ~= nil then
      return
    end
    view.open { focus_tree = false }
    require("nvim-tree.renderer").draw()
  end
end

local function find_existing_windows()
  return vim.tbl_filter(function(win)
    local buf = api.nvim_win_get_buf(win)
    return api.nvim_buf_get_name(buf):match "NvimTree" ~= nil
  end, api.nvim_list_wins())
end

local function is_file_readable(fname)
  local stat = luv.fs_stat(fname)
  return stat and stat.type == "file" and luv.fs_access(fname, "R")
end

local function update_base_dir_with_filepath(filepath, bufnr)
  local ft = api.nvim_buf_get_option(bufnr, "filetype") or ""
  for _, value in pairs(_config.update_focused_file.ignore_list) do
    if utils.str_find(filepath, value) or utils.str_find(ft, value) then
      return
    end
  end

  if not vim.startswith(filepath, core.get_cwd()) then
    change_dir.fn(vim.fn.fnamemodify(filepath, ":p:h"))
  end
end

function M.find_file(with_open, bufnr)
  if not with_open and not core.get_explorer() then
    return
  end

  bufnr = bufnr or api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local filepath = utils.canonical_path(vim.fn.fnamemodify(bufname, ":p"))
  if not is_file_readable(filepath) then
    return
  end

  if with_open then
    M.open()
  end

  vim.schedule(function()
    -- if we don't schedule, it will search for NvimTree
    if _config.update_focused_file.update_cwd then
      update_base_dir_with_filepath(filepath, bufnr)
    end
    require("nvim-tree.actions.find-file").fn(filepath)
  end)
end

M.resize = view.resize

function M.open_on_directory()
  local should_proceed = M.initialized and (_config.hijack_directories.auto_open or view.is_visible())
  if not should_proceed then
    return
  end

  local buf = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) ~= 1 then
    return
  end

  change_dir.force_dirchange(bufname, true)
end

function M.reset_highlight()
  colors.setup()
  renderer.render_hl(view.get_bufnr())
end

local prev_line
function M.place_cursor_on_node()
  local l = api.nvim_win_get_cursor(0)[1]
  if l == prev_line then
    return
  end
  prev_line = l

  local node = lib.get_node_at_cursor()
  if not node or node.name == ".." then
    return
  end

  local line = api.nvim_get_current_line()
  local cursor = api.nvim_win_get_cursor(0)
  local idx = vim.fn.stridx(line, node.name)

  if idx >= 0 then
    api.nvim_win_set_cursor(0, { cursor[1], idx })
  end
end

function M.on_enter(netrw_disabled)
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local buftype = api.nvim_buf_get_option(bufnr, "filetype")
  local ft_ignore = _config.ignore_ft_on_setup

  local stats = luv.fs_stat(bufname)
  local is_dir = stats and stats.type == "directory"
  local is_file = stats and stats.type == "file"
  local cwd
  if is_dir then
    cwd = vim.fn.expand(bufname)
    -- INFO: could potentially conflict with rooter plugins
    vim.cmd("noautocmd cd " .. cwd)
  end

  local lines = not is_dir and api.nvim_buf_get_lines(bufnr, 0, -1, false) or {}
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
    api.nvim_set_current_win(existing_tree_wins[1])
  end

  if should_open or should_hijack or existing_tree_wins[1] ~= nil then
    lib.open(cwd)

    if should_focus_other_window then
      vim.cmd "noautocmd wincmd p"
      if should_find then
        M.find_file(false)
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

local function setup_vim_commands()
  api.nvim_create_user_command("NvimTreeOpen", function(res)
    M.open(res.args)
  end, { nargs = "?", complete = "dir" })
  api.nvim_create_user_command("NvimTreeClose", view.close, {})
  api.nvim_create_user_command("NvimTreeToggle", function(res)
    M.toggle(false, false, res.args)
  end, { nargs = "?", complete = "dir" })
  api.nvim_create_user_command("NvimTreeFocus", M.focus, {})
  api.nvim_create_user_command("NvimTreeRefresh", reloaders.reload_explorer, {})
  api.nvim_create_user_command("NvimTreeClipboard", copy_paste.print_clipboard, {})
  api.nvim_create_user_command("NvimTreeFindFile", function()
    M.find_file(true)
  end, {})
  api.nvim_create_user_command("NvimTreeFindFileToggle", function(res)
    M.toggle(true, false, res.args)
  end, { nargs = "?", complete = "dir" })
  api.nvim_create_user_command("NvimTreeResize", function(res)
    M.resize(res.args)
  end, { nargs = 1 })
  api.nvim_create_user_command("NvimTreeCollapse", collapse_all.fn, {})
  api.nvim_create_user_command("NvimTreeCollapseKeepBuffers", function()
    collapse_all.fn(true)
  end, {})
end

function M.change_dir(name)
  change_dir.fn(name)

  if _config.update_focused_file.enable then
    M.find_file(false)
  end
end

local function setup_autocommands(opts)
  local augroup_id = api.nvim_create_augroup("NvimTree", {})
  local function create_nvim_tree_autocmd(name, custom_opts)
    local default_opts = { group = augroup_id }
    api.nvim_create_autocmd(name, vim.tbl_extend("force", default_opts, custom_opts))
  end

  -- reset highlights when colorscheme is changed
  create_nvim_tree_autocmd("ColorScheme", { callback = M.reset_highlight })

  local has_watchers = opts.filesystem_watchers.enable

  if opts.auto_reload_on_write and not has_watchers then
    create_nvim_tree_autocmd("BufWritePost", { callback = reloaders.reload_explorer })
  end

  if not has_watchers and opts.git.enable then
    create_nvim_tree_autocmd("User", {
      pattern = { "FugitiveChanged", "NeogitStatusRefreshed" },
      callback = reloaders.reload_git,
    })
  end

  if opts.open_on_tab then
    create_nvim_tree_autocmd("TabEnter", { callback = M.tab_change })
  end
  if opts.hijack_cursor then
    create_nvim_tree_autocmd("CursorMoved", { pattern = "NvimTree_*", callback = M.place_cursor_on_node })
  end
  if opts.update_cwd then
    create_nvim_tree_autocmd("DirChanged", {
      callback = function()
        M.change_dir(vim.loop.cwd())
      end,
    })
  end
  if opts.update_focused_file.enable then
    create_nvim_tree_autocmd("BufEnter", {
      callback = function()
        M.find_file(false)
      end,
    })
  end

  if not opts.actions.open_file.quit_on_open then
    create_nvim_tree_autocmd("BufWipeout", { pattern = "NvimTree_*", callback = view._prevent_buffer_override })
  else
    create_nvim_tree_autocmd("BufWipeout", { pattern = "NvimTree_*", callback = view.abandon_current_window })
  end

  if opts.hijack_directories.enable then
    create_nvim_tree_autocmd({ "BufEnter", "BufNewFile" }, { callback = M.open_on_directory })
  end

  if opts.reload_on_bufenter and not has_watchers then
    create_nvim_tree_autocmd("BufEnter", { pattern = "NvimTree_*", callback = reloaders.reload_explorer })
  end

  if opts.view.centralize_selection then
    create_nvim_tree_autocmd("BufEnter", {
      pattern = "NvimTree_*",
      callback = function()
        vim.schedule(function()
          local keys = api.nvim_replace_termcodes("zz", true, false, true)
          api.nvim_feedkeys(keys, "n", true)
        end)
      end,
    })
  end
end

local DEFAULT_OPTS = { -- BEGIN_DEFAULT_OPTS
  auto_reload_on_write = true,
  create_in_closed_folder = false,
  disable_netrw = false,
  hijack_cursor = false,
  hijack_netrw = true,
  hijack_unnamed_buffer_when_opening = false,
  ignore_buffer_on_setup = false,
  open_on_setup = false,
  open_on_setup_file = false,
  open_on_tab = false,
  sort_by = "name",
  update_cwd = false,
  reload_on_bufenter = false,
  respect_buf_cwd = false,
  view = {
    adaptive_size = false,
    centralize_selection = false,
    width = 30,
    height = 30,
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
  },
  renderer = {
    add_trailing = false,
    group_empty = false,
    highlight_git = false,
    full_name = false,
    highlight_opened_files = "none",
    root_folder_modifier = ":~",
    indent_markers = {
      enable = false,
      icons = {
        corner = "└ ",
        edge = "│ ",
        item = "│ ",
        none = "  ",
      },
    },
    icons = {
      webdev_colors = true,
      git_placement = "before",
      padding = " ",
      symlink_arrow = " ➛ ",
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
      glyphs = {
        default = "",
        symlink = "",
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
  },
  hijack_directories = {
    enable = true,
    auto_open = true,
  },
  update_focused_file = {
    enable = false,
    update_cwd = false,
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
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  filters = {
    dotfiles = false,
    custom = {},
    exclude = {},
  },
  filesystem_watchers = {
    enable = false,
    interval = 100,
  },
  git = {
    enable = true,
    ignore = true,
    timeout = 400,
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
    },
    open_file = {
      quit_on_open = false,
      resize_window = true,
      window_picker = {
        enable = true,
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
    require_confirm = true,
  },
  live_filter = {
    prefix = "[FILTER]: ",
    always_show_folders = true,
  },
  log = {
    enable = false,
    truncate = false,
    types = {
      all = false,
      config = false,
      copy_paste = false,
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

local FIELD_OVERRIDE_TYPECHECK = {
  width = { string = true, ["function"] = true, number = true },
  height = { string = true, ["function"] = true, number = true },
}

local function validate_options(conf)
  local msg

  local function validate(user, def, prefix)
    -- only compare tables with contents that are not integer indexed
    if type(user) ~= "table" or type(def) ~= "table" or not next(def) or type(next(def)) == "number" then
      return
    end

    for k, v in pairs(user) do
      local invalid
      local override_typecheck = FIELD_OVERRIDE_TYPECHECK[k] or {}
      if def[k] == nil then
        -- option does not exist
        invalid = string.format("unknown option: %s%s", prefix, k)
      elseif type(v) ~= type(def[k]) and not override_typecheck[type(v)] then
        -- option is of the wrong type and is not a function
        invalid = string.format("invalid option: %s%s expected: %s actual: %s", prefix, k, type(def[k]), type(v))
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

  validate(conf, DEFAULT_OPTS, "")

  if msg then
    utils.warn(msg)
  end
end

function M.setup(conf)
  if vim.fn.has "nvim-0.7" == 0 then
    utils.warn "nvim-tree.lua requires Neovim 0.7 or higher"
    return
  end

  if M.setup_called then
    utils.warn "nvim-tree.lua setup called multiple times"
    return
  end
  M.setup_called = true

  legacy.migrate_legacy_options(conf or {})

  validate_options(conf)

  local opts = merge_options(conf)
  local netrw_disabled = opts.disable_netrw or opts.hijack_netrw

  _config.update_focused_file = opts.update_focused_file
  _config.open_on_setup = opts.open_on_setup
  _config.open_on_setup_file = opts.open_on_setup_file
  _config.ignore_buffer_on_setup = opts.ignore_buffer_on_setup
  _config.ignore_ft_on_setup = opts.ignore_ft_on_setup
  _config.hijack_directories = opts.hijack_directories
  _config.hijack_directories.enable = _config.hijack_directories.enable and netrw_disabled

  manage_netrw(opts.disable_netrw, opts.hijack_netrw)

  M.config = opts
  require("nvim-tree.log").setup(opts)

  log.line("config", "default config + user")
  log.raw("config", "%s\n", vim.inspect(opts))

  require("nvim-tree.actions").setup(opts)
  require("nvim-tree.colors").setup()
  require("nvim-tree.diagnostics").setup(opts)
  require("nvim-tree.explorer").setup(opts)
  require("nvim-tree.git").setup(opts)
  require("nvim-tree.view").setup(opts)
  require("nvim-tree.lib").setup(opts)
  require("nvim-tree.renderer").setup(opts)
  require("nvim-tree.live-filter").setup(opts)
  if M.config.renderer.icons.show.file and pcall(require, "nvim-web-devicons") then
    require("nvim-web-devicons").setup()
  end

  setup_vim_commands()
  setup_autocommands(opts)

  vim.schedule(function()
    M.on_enter(netrw_disabled)
  end)
end

return M
