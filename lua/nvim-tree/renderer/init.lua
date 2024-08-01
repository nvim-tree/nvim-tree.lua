local core = require "nvim-tree.core"
local log = require "nvim-tree.log"
local view = require "nvim-tree.view"
local events = require "nvim-tree.events"

local _padding = require "nvim-tree.renderer.components.padding"
local icon_component = require "nvim-tree.renderer.components.icons"
local full_name = require "nvim-tree.renderer.components.full-name"
local Builder = require "nvim-tree.renderer.builder"

local M = {}

local SIGN_GROUP = "NvimTreeRendererSigns"

local namespace_highlights_id = vim.api.nvim_create_namespace "NvimTreeHighlights"
local namespace_extmarks_id = vim.api.nvim_create_namespace "NvimTreeExtmarks"
local namespace_size_extmarks_id = vim.api.nvim_create_namespace "NvimTreeSizeExtmarks"

---@param bufnr number
---@param lines string[]
---@param hl_args AddHighlightArgs[]
---@param signs string[]
---@param extmarks table<integer, HighlightedString[]>
---@param size_extmarks table<integer, HighlightedString[]>
local function _draw(bufnr, lines, hl_args, signs, extmarks, size_extmarks)
  if vim.fn.has "nvim-0.10" == 1 then
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  else
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true) ---@diagnostic disable-line: deprecated
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  M.render_hl(bufnr, hl_args)

  if vim.fn.has "nvim-0.10" == 1 then
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  else
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false) ---@diagnostic disable-line: deprecated
  end

  vim.fn.sign_unplace(SIGN_GROUP)
  for i, sign_name in pairs(signs) do
    vim.fn.sign_place(0, SIGN_GROUP, sign_name, bufnr, { lnum = i + 1 })
  end

  M.render_extmarks(bufnr, namespace_extmarks_id, extmarks)
  M.render_extmarks(bufnr, namespace_size_extmarks_id, size_extmarks)
end

function M.render_hl(bufnr, hl)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_highlights_id, 0, -1)
  for _, data in ipairs(hl) do
    if type(data[1]) == "table" then
      for _, group in ipairs(data[1]) do
        vim.api.nvim_buf_add_highlight(bufnr, namespace_highlights_id, group, data[2], data[3], data[4])
      end
    end
  end
end

function M.render_extmarks(bufnr, ns_id, extmarks)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  for i, extname in pairs(extmarks) do
    for _, mark in ipairs(extname) do
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, -1, {
        virt_text = { { mark.str, mark.hl } },
        virt_text_pos = "right_align",
        hl_mode = "combine",
      })
    end
  end
end

-- Here we do a partial redraw of only a subsection of extra marks.
-- We could simply call reloaders.reload(), but that would be substantially slower.
-- Calling `nvim_buf_clear_namespace` to hide size information
-- and `render_extmarks` to show again is preferable in place of
-- reloading all decorators, nodes and lines from scratch, since resize does not trigger a reload.
local redraw_size_extmarks = false
function M.on_resize()
  if M.builder == nil then
    return
  end

  local bufnr = view.get_bufnr()

  if view.get_current_width() < M.config.size.width_cutoff then
    redraw_size_extmarks = true
    vim.api.nvim_buf_clear_namespace(bufnr, namespace_size_extmarks_id, 0, -1)
    return
  end

  -- If we got here, we only need to know if we should redraw
  -- We don't have to check if decorator_size is enbaled, because if it's
  -- not, then size_extmarks would've been empty
  if redraw_size_extmarks then
    redraw_size_extmarks = false
    M.render_extmarks(bufnr, namespace_size_extmarks_id, M.builder.size_extmarks)
  end
end

function M.draw()
  local bufnr = view.get_bufnr()
  if not core.get_explorer() or not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local profile = log.profile_start "draw"

  local cursor = vim.api.nvim_win_get_cursor(view.get_winnr() or 0)
  icon_component.reset_config()

  redraw_size_extmarks = false
  M.builder = Builder:new():build()
  _draw(bufnr, M.builder.lines, M.builder.hl_args, M.builder.signs, M.builder.extmarks, M.builder.size_extmarks)

  if cursor and #M.builder.lines >= cursor[1] then
    vim.api.nvim_win_set_cursor(view.get_winnr() or 0, cursor)
  end

  view.grow_from_content()

  log.profile_end(profile)

  events._dispatch_on_tree_rendered(bufnr, view.get_winnr())
end

function M.setup(opts)
  M.config = opts.renderer
  M.builder = nil
  _padding.setup(opts)
  full_name.setup(opts)
  icon_component.setup(opts)
  Builder.setup(opts)
end

return M
