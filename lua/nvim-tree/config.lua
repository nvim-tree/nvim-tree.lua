--This will be required after api, before setup.
--This file should have minimal requires that are cheap and have no dependencies or are already required.

local notify = require("nvim-tree.notify")
local legacy = require("nvim-tree.legacy")
local utils = require("nvim-tree.utils")

-- short names like g are used rather than getters to keep code brief

local M = {
  ---@type nvim_tree.config immutable default config
  d = {},

  ---@type nvim_tree.config? global current config, nil until setup called
  g = nil,

  ---@type nvim_tree.config? raw user config, nil when no user config passed to setup
  u = nil,
}

M.d = { -- config-default-start
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
    max_events = 0,
    ignore_dirs = {
      "/.ccls-cache",
      "/build",
      "/node_modules",
      "/target",
      "/.zig-cache",
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
} -- config-default-end

-- Immediately apply OS specific localisations to defaults
if utils.is_macos or utils.is_windows then
  M.d.trash.cmd = "trash"
end
if utils.is_windows then
  DEFAULT.filesystem_watchers.max_events = 1000
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

---Validate types and values of the user supplied config.
---Warns and removes invalid in place.
---@param u nvim_tree.config
local function validate_config(u)
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

  validate(u, M.d, ACCEPTED_STRINGS, ACCEPTED_TYPES, ACCEPTED_ENUMS, "")

  if msg then
    notify.warn(msg .. "\n\nsee :help nvim-tree-config for available configuration options")
  end
end

---Validate user config and migrate legacy.
---Merge with M.d and persist as M.g
---When no user config M.g is set to M.d and M.u is set to nil
---@param u? nvim_tree.config user supplied subset of config
function M.setup(u)
  if not u or type(u) ~= "table" then
    if u then
      notify.warn(string.format("invalid config type \"%s\" passed to setup, using defaults", type(u)))
    end
    M.g = vim.deepcopy(M.d)
    M.u = nil
    return
  end

  -- retain user for reference
  M.u = vim.deepcopy(u)

  legacy.migrate_config(u)

  validate_config(u)

  -- set global to the validated and populated user config
  M.g = vim.tbl_deep_extend("force", M.d, u)
end

---Deep clone defaults
---@return nvim_tree.config
function M.d_clone()
  return vim.deepcopy(M.d)
end

---Deep clone user
---@return nvim_tree.config? nil when no config passed to setup
function M.u_clone()
  return vim.deepcopy(M.u)
end

---Deep clone global
---@return nvim_tree.config? nil when setup not called
function M.g_clone()
  return vim.deepcopy(M.g)
end

return M
