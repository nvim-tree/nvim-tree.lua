local core = require "nvim-tree.core"
local diagnostics = require "nvim-tree.diagnostics"
local log = require "nvim-tree.log"
local view = require "nvim-tree.view"

local _padding = require "nvim-tree.renderer.components.padding"
local icon_component = require "nvim-tree.renderer.components.icons"
local full_name = require "nvim-tree.renderer.components.full-name"
local help = require "nvim-tree.renderer.help"
local git = require "nvim-tree.renderer.components.git"
local Builder = require "nvim-tree.renderer.builder"
local live_filter = require "nvim-tree.live-filter"
local marks = require "nvim-tree.marks"

local M = {
  last_highlights = {},
}

local namespace_id = vim.api.nvim_create_namespace "NvimTreeHighlights"

local function _draw(bufnr, lines, hl, signs)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  M.render_hl(bufnr, hl)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.fn.sign_unplace(git.SIGN_GROUP)
  for _, sign in pairs(signs) do
    vim.fn.sign_place(0, git.SIGN_GROUP, sign.sign, bufnr, { lnum = sign.lnum, priority = 1 })
  end
end

function M.render_hl(bufnr, hl)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl or M.last_highlights) do
    vim.api.nvim_buf_add_highlight(bufnr, namespace_id, data[1], data[2], data[3], data[4])
  end
end

local picture_map = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
}

function M.draw()
  local bufnr = view.get_bufnr()
  if not core.get_explorer() or not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local ps = log.profile_start "draw"

  local cursor = vim.api.nvim_win_get_cursor(view.get_winnr())
  icon_component.reset_config()

  local lines, hl
  local signs = {}
  if view.is_help_ui() then
    lines, hl = help.compute_lines()
  else
    lines, hl, signs = Builder.new(core.get_cwd())
      :configure_root_label(M.config.root_folder_label)
      :configure_trailing_slash(M.config.add_trailing)
      :configure_special_files(M.config.special_files)
      :configure_picture_map(picture_map)
      :configure_opened_file_highlighting(M.config.highlight_opened_files)
      :configure_git_icons_padding(M.config.icons.padding)
      :configure_git_icons_placement(M.config.icons.git_placement)
      :configure_symlink_destination(M.config.symlink_destination)
      :configure_filter(live_filter.filter, live_filter.prefix)
      :build_header(view.is_root_folder_visible(core.get_cwd()))
      :build(core.get_explorer())
      :unwrap()
  end

  _draw(bufnr, lines, hl, signs)

  M.last_highlights = hl

  if cursor and #lines >= cursor[1] then
    vim.api.nvim_win_set_cursor(view.get_winnr(), cursor)
  end

  if view.is_help_ui() then
    diagnostics.clear()
    marks.clear()
  else
    diagnostics.update()
    marks.draw()
  end

  view.grow_from_content()

  log.profile_end(ps, "draw")
end

function M.setup(opts)
  M.config = opts.renderer

  _padding.setup(opts)
  full_name.setup(opts)
  git.setup(opts)
  icon_component.setup(opts)
end

return M
