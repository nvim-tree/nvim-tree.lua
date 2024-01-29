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

local namespace_id = vim.api.nvim_create_namespace "NvimTreeHighlights"

---@param bufnr number
---@param lines string[]
---@param hl_args AddHighlightArgs[]
---@param signs string[]
local function _draw(bufnr, lines, hl_args, signs)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  M.render_hl(bufnr, hl_args)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.fn.sign_unplace(SIGN_GROUP)
  for i, sign_name in pairs(signs) do
    vim.fn.sign_place(0, SIGN_GROUP, sign_name, bufnr, { lnum = i + 1 })
  end
end

function M.render_hl(bufnr, hl)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl) do
    if type(data[1]) == "table" then
      for _, group in ipairs(data[1]) do
        vim.api.nvim_buf_add_highlight(bufnr, namespace_id, group, data[2], data[3], data[4])
      end
    end
  end
end

function M.draw()
  local bufnr = view.get_bufnr()
  if not core.get_explorer() or not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local profile = log.profile_start "draw"

  local cursor = vim.api.nvim_win_get_cursor(view.get_winnr())
  icon_component.reset_config()

  local builder = Builder:new():build()

  _draw(bufnr, builder.lines, builder.hl_args, builder.signs)

  if cursor and #builder.lines >= cursor[1] then
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

  Builder.setup(opts)
end

return M
