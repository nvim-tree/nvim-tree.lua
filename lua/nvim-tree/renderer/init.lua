local core = require "nvim-tree.core"
local log = require "nvim-tree.log"
local view = require "nvim-tree.view"
local events = require "nvim-tree.events"

local _padding = require "nvim-tree.renderer.components.padding"
local icon_component = require "nvim-tree.renderer.components.icons"
local full_name = require "nvim-tree.renderer.components.full-name"
local Builder = require "nvim-tree.renderer.builder"
local live_filter = require "nvim-tree.live-filter"

local DecoratorBookmarks = require "nvim-tree.renderer.decorator.bookmarks"
local DecoratorCopied = require "nvim-tree.renderer.decorator.copied"
local DecoratorCut = require "nvim-tree.renderer.decorator.cut"
local DecoratorDiagnostics = require "nvim-tree.renderer.decorator.diagnostics"
local DecoratorGit = require "nvim-tree.renderer.decorator.git"
local DecoratorModified = require "nvim-tree.renderer.decorator.modified"
local DecoratorOpened = require "nvim-tree.renderer.decorator.opened"

local M = {
  last_highlights = {},
  decorators = {},
  deco = {},
}

local SIGN_GROUP = "NvimTreeRendererSigns"

local namespace_id = vim.api.nvim_create_namespace "NvimTreeHighlights"

local function _draw(bufnr, lines, hl, sign_names)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  M.render_hl(bufnr, hl)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.fn.sign_unplace(SIGN_GROUP)
  for i, sign_name in pairs(sign_names) do
    vim.fn.sign_place(0, SIGN_GROUP, sign_name, bufnr, { lnum = i + 1 })
  end
end

function M.render_hl(bufnr, hl)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl or M.last_highlights) do
    if type(data[1]) == "table" then
      for _, group in ipairs(data[1]) do
        vim.api.nvim_buf_add_highlight(bufnr, namespace_id, group, data[2], data[3], data[4])
      end
    end
  end
end

local picture_map = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
  webp = true,
  jxl = true,
}

function M.draw()
  local bufnr = view.get_bufnr()
  if not core.get_explorer() or not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local profile = log.profile_start "draw"

  local cursor = vim.api.nvim_win_get_cursor(view.get_winnr())
  icon_component.reset_config()

  local lines, hl, sign_names = Builder.new(core.get_cwd(), M.deco)
    :configure_root_label(M.config.root_folder_label)
    :configure_trailing_slash(M.config.add_trailing)
    :configure_special_files(M.config.special_files)
    :configure_picture_map(picture_map)
    :configure_icon_padding(M.config.icons.padding)
    :configure_symlink_destination(M.config.symlink_destination)
    :configure_filter(live_filter.filter, live_filter.prefix)
    :configure_group_name_modifier(M.config.group_empty)
    :build_header(view.is_root_folder_visible(core.get_cwd()))
    :build(core.get_explorer())
    :unwrap()

  _draw(bufnr, lines, hl, sign_names)

  M.last_highlights = hl

  if cursor and #lines >= cursor[1] then
    vim.api.nvim_win_set_cursor(view.get_winnr(), cursor)
  end

  view.grow_from_content()

  log.profile_end(profile)

  events._dispatch_on_tree_rendered(bufnr, view.get_winnr())
end

function M.setup(opts)
  M.config = opts.renderer

  _padding.setup(opts)
  full_name.setup(opts)
  icon_component.setup(opts)

  -- priority order
  M.deco = {
    DecoratorCut:new(opts),
    DecoratorCopied:new(opts),
    DecoratorDiagnostics:new(opts),
    DecoratorBookmarks:new(opts),
    DecoratorModified:new(opts),
    DecoratorOpened:new(opts),
    DecoratorGit:new(opts),
  }
end

return M
