local utils = require "nvim-tree.utils"
local notify = require "nvim-tree.notify"

local M = {}

local function refactored(opts)
  -- 2022/06/20
  utils.move_missing_val(opts, "update_focused_file", "update_cwd", opts, "update_focused_file", "update_root", true)
  utils.move_missing_val(opts, "", "update_cwd", opts, "", "sync_root_with_cwd", true)

  -- 2022/11/07
  utils.move_missing_val(opts, "", "open_on_tab", opts, "tab.sync", "open", false)
  utils.move_missing_val(opts, "", "open_on_tab", opts, "tab.sync", "close", true)
  utils.move_missing_val(opts, "", "ignore_buf_on_tab_change", opts, "tab.sync", "ignore", true)

  -- 2022/11/22
  utils.move_missing_val(opts, "renderer", "root_folder_modifier", opts, "renderer", "root_folder_label", true)

  -- 2023/01/01
  utils.move_missing_val(opts, "update_focused_file", "debounce_delay", opts, "view", "debounce_delay", true)

  -- 2023/01/08
  utils.move_missing_val(opts, "trash", "require_confirm", opts, "ui.confirm", "trash", true)

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
  utils.move_missing_val(opts, "", "sort_by", opts, "sort", "sorter", true)

  -- 2023/07/16
  utils.move_missing_val(opts, "git", "ignore", opts, "filters", "git_ignored", true)

  -- 2023/08/26
  utils.move_missing_val(opts, "renderer.icons", "webdev_colors", opts, "renderer.icons.web_devicons.file", "color", true)
end

local function deprecated(opts)
  if type(opts.view) == "table" and opts.view.hide_root_folder then
    notify.info "view.hide_root_folder is deprecated, please set renderer.root_folder_label = false"
  end
end

local function removed(opts)
  if opts.auto_close then
    notify.warn "auto close feature has been removed, see note in the README (tips & reminder section)"
    opts.auto_close = nil
  end

  if opts.focus_empty_on_setup then
    notify.warn "focus_empty_on_setup has been removed and will be replaced by a new startup configuration. Please remove this option. See https://bit.ly/3yJch2T"
    opts.focus_empty_on_setup = nil
  end

  if opts.create_in_closed_folder then
    notify.warn "create_in_closed_folder has been removed and is now the default behaviour. You may use api.fs.create to add a file under your desired node."
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

return M
