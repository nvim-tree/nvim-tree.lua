local notify = require("nvim-tree.notify")

local M = {}

--- Create empty sub-tables if not present
---@param tbl table to create empty inside of
---@param path string dot separated string of sub-tables
---@return table deepest sub-table
local function create(tbl, path)
  local t = tbl
  for s in string.gmatch(path, "([^%.]+)%.*") do
    if t[s] == nil then
      t[s] = {}
    end
    t = t[s]
  end

  return t
end

--- Move a value from src to dst if value is nil on dst.
--- Remove value from src
---@param src table to copy from
---@param src_path string dot separated string of sub-tables
---@param src_pos string value pos
---@param dst table to copy to
---@param dst_path string dot separated string of sub-tables, created when missing
---@param dst_pos string value pos
---@param remove boolean
local function move(src, src_path, src_pos, dst, dst_path, dst_pos, remove)
  for pos in string.gmatch(src_path, "([^%.]+)%.*") do
    if src[pos] and type(src[pos]) == "table" then
      src = src[pos]
    else
      return
    end
  end
  local src_val = src[src_pos]
  if src_val == nil then
    return
  end

  dst = create(dst, dst_path)
  if dst[dst_pos] == nil then
    dst[dst_pos] = src_val
  end

  if remove then
    src[src_pos] = nil
  end
end

-- silently move, please add to help nvim-tree-legacy-opts
local function refactored(opts)
  -- 2022/06/20
  move(opts, "update_focused_file", "update_cwd", opts, "update_focused_file", "update_root",        true)
  move(opts, "",                    "update_cwd", opts, "",                    "sync_root_with_cwd", true)

  -- 2022/11/07
  move(opts, "", "open_on_tab",              opts, "tab.sync", "open",   false)
  move(opts, "", "open_on_tab",              opts, "tab.sync", "close",  true)
  move(opts, "", "ignore_buf_on_tab_change", opts, "tab.sync", "ignore", true)

  -- 2022/11/22
  move(opts, "renderer", "root_folder_modifier", opts, "renderer", "root_folder_label", true)

  -- 2023/01/01
  move(opts, "update_focused_file", "debounce_delay", opts, "view", "debounce_delay", true)

  -- 2023/01/08
  move(opts, "trash", "require_confirm", opts, "ui.confirm", "trash", true)

  -- 2023/01/15
  if type(opts.view) == "table" and opts.view.adaptive_size ~= nil then
    if opts.view.adaptive_size and type(opts.view.width) ~= "table" then
      local width = opts.view.width
      opts.view.width = {
        min = width,
      }
    end
    opts.view.adaptive_size = nil
  end

  -- 2023/07/15
  move(opts, "", "sort_by", opts, "sort", "sorter", true)

  -- 2023/07/16
  move(opts, "git", "ignore", opts, "filters", "git_ignored", true)

  -- 2023/08/26
  move(opts, "renderer.icons", "webdev_colors", opts, "renderer.icons.web_devicons.file", "color", true)

  -- 2023/10/08
  if type(opts.renderer) == "table" and type(opts.renderer.highlight_diagnostics) == "boolean" then
    opts.renderer.highlight_diagnostics = opts.renderer.highlight_diagnostics and "name" or "none"
  end

  -- 2023/10/21
  if type(opts.renderer) == "table" and type(opts.renderer.highlight_git) == "boolean" then
    opts.renderer.highlight_git = opts.renderer.highlight_git and "name" or "none"
  end

  -- 2024/02/15
  if type(opts.update_focused_file) == "table" then
    if type(opts.update_focused_file.update_root) ~= "table" then
      opts.update_focused_file.update_root = { enable = opts.update_focused_file.update_root }
    end
  end
  move(opts, "update_focused_file", "ignore_list", opts, "update_focused_file.update_root", "ignore_list", true)

  -- 2025/04/30
  if opts.renderer and opts.renderer.icons and type(opts.renderer.icons.padding) == "string" then
    local icons_padding = opts.renderer.icons.padding
    opts.renderer.icons.padding = {}
    opts.renderer.icons.padding.icon = icons_padding
  end
end

local function deprecated(opts)
  if type(opts.view) == "table" and opts.view.hide_root_folder then
    notify.info("view.hide_root_folder is deprecated, please set renderer.root_folder_label = false")
  end
end

local function removed(opts)
  if opts.auto_close then
    notify.warn("auto close feature has been removed: https://github.com/nvim-tree/nvim-tree.lua/wiki/Auto-Close")
    opts.auto_close = nil
  end

  if opts.focus_empty_on_setup then
    notify.warn("focus_empty_on_setup has been removed: https://github.com/nvim-tree/nvim-tree.lua/wiki/Open-At-Startup")
    opts.focus_empty_on_setup = nil
  end

  if opts.create_in_closed_folder then
    notify.warn(
      "create_in_closed_folder has been removed and is now the default behaviour. You may use api.fs.create to add a file under your desired node.")
  end
  opts.create_in_closed_folder = nil
end

function M.migrate_legacy_options(opts)
  -- silently move
  refactored(opts)

  -- warn
  deprecated(opts)

  -- warn and delete
  removed(opts)
end

---Silently create new api entries pointing legacy functions to current
---@param api table not properly typed to prevent LSP from referencing implementations
function M.map_api(api)
  api.config = api.config or {}
  api.config.mappings = api.config.mappings or {}
  api.config.mappings.get_keymap = api.map.keymap.current
  api.config.mappings.get_keymap_default = api.map.keymap.default
  api.config.mappings.default_on_attach = api.map.on_attach.default

  api.live_filter = api.live_filter or {}
  api.live_filter.start = api.filter.live.start
  api.live_filter.clear = api.filter.live.clear

  api.tree = api.tree or {}
  api.tree.toggle_enable_filters = api.filter.toggle
  api.tree.toggle_gitignore_filter = api.filter.git.ignored.toggle
  api.tree.toggle_git_clean_filter = api.filter.git.clean.toggle
  api.tree.toggle_no_buffer_filter = api.filter.no_buffer.toggle
  api.tree.toggle_custom_filter = api.filter.custom.toggle
  api.tree.toggle_hidden_filter = api.filter.dotfiles.toggle
  api.tree.toggle_no_bookmark_filter = api.filter.no_bookmark.toggle

  api.diagnostics = api.diagnostics or {}
  api.diagnostics.hi_test = api.appearance.hi_test

  api.decorator.UserDecorator = api.Decorator
end

return M
