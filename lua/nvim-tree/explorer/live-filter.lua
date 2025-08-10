local view = require("nvim-tree.view")
local utils = require("nvim-tree.utils")

local Class = require("nvim-tree.classic")
local Iterator = require("nvim-tree.iterators.node-iterator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) LiveFilter: Class
---@field explorer Explorer
---@field prefix string
---@field always_show_folders boolean
---@field filter string
local LiveFilter = Class:extend()

---@class LiveFilter
---@overload fun(args: LiveFilterArgs): LiveFilter

---@class (exact) LiveFilterArgs
---@field explorer Explorer

---@protected
---@param args LiveFilterArgs
function LiveFilter:new(args)
  self.explorer = args.explorer
  self.prefix = self.explorer.opts.live_filter.prefix
  self.always_show_folders = self.explorer.opts.live_filter.always_show_folders
  self.filter = nil
end

---@param node_ Node?
local function reset_filter(self, node_)
  node_ = node_ or self.explorer

  if node_ == nil then
    return
  end

  local dir_ = node_:as(DirectoryNode)
  if dir_ then
    dir_.hidden_stats = vim.tbl_deep_extend("force", dir_.hidden_stats or {}, { live_filter = 0, })
  end

  Iterator.builder(node_.nodes)
    :hidden()
    :applier(function(node)
      node.hidden = false
      local dir = node:as(DirectoryNode)
      if dir then
        dir.hidden_stats = vim.tbl_deep_extend("force", dir.hidden_stats or {}, { live_filter = 0, })
      end
    end)
    :iterate()
end

local overlay_bufnr = 0
local overlay_winnr = 0

local function remove_overlay(self)
  if view.View.float.enable and view.View.float.quit_on_focus_loss then
    -- return to normal nvim-tree float behaviour when filter window is closed
    vim.api.nvim_create_autocmd("WinLeave", {
      pattern = "NvimTree_*",
      group = vim.api.nvim_create_augroup("NvimTree", { clear = false }),
      callback = function()
        if utils.is_nvim_tree_buf(0) then
          view.close()
        end
      end,
    })
  end

  vim.api.nvim_win_close(overlay_winnr, true)
  vim.api.nvim_buf_delete(overlay_bufnr, { force = true })
  overlay_bufnr = 0
  overlay_winnr = 0

  if self.filter == "" then
    self:clear_filter()
  end
end

---@param node Node
---@return boolean
local function matches(self, node)
  if not self.explorer.filters.enabled then
    return true
  end

  local path = node.absolute_path
  local name = vim.fn.fnamemodify(path, ":t")
  return vim.regex(self.filter):match_str(name) ~= nil
end

---@param node_ DirectoryNode?
function LiveFilter:apply_filter(node_)
  if not self.filter or self.filter == "" then
    reset_filter(self, node_)
    return
  end

  -- this iterator cannot yet be refactored with the Iterator module
  -- since the node mapper is based on its children
  local function iterate(node)
    local filtered_nodes = 0
    local nodes = node.group_next and { node.group_next } or node.nodes

    node.hidden_stats = vim.tbl_deep_extend("force", node.hidden_stats or {}, {
      live_filter = 0,
    })

    if nodes then
      for _, n in pairs(nodes) do
        iterate(n)
        if n.hidden then
          filtered_nodes = filtered_nodes + 1
        end
      end
    end

    node.hidden_stats.live_filter = filtered_nodes

    local has_nodes = nodes and (self.always_show_folders or #nodes > filtered_nodes)
    local ok, is_match = pcall(matches, self, node)
    node.hidden = not (has_nodes or (ok and is_match))
  end

  iterate(node_ or self.explorer)
end

local function record_char(self)
  vim.schedule(function()
    self.filter = vim.api.nvim_buf_get_lines(overlay_bufnr, 0, -1, false)[1]
    self:apply_filter()
    self.explorer.renderer:draw()
  end)
end

local function configure_buffer_overlay(self)
  overlay_bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_attach(overlay_bufnr, true, {
    on_lines = function()
      return record_char(self)
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      return remove_overlay(self)
    end,
    once = true,
  })

  vim.api.nvim_buf_set_keymap(overlay_bufnr, "i", "<CR>", "<cmd>stopinsert<CR>", {})
end

---@return integer
local function calculate_overlay_win_width(self)
  local wininfo = vim.fn.getwininfo(view.get_winnr())[1]

  if wininfo then
    return wininfo.width - wininfo.textoff - #self.prefix
  end

  return 20
end

local function create_overlay(self)
  if view.View.float.enable then
    -- don't close nvim-tree float when focus is changed to filter window
    vim.api.nvim_clear_autocmds({
      event   = "WinLeave",
      pattern = "NvimTree_*",
      group   = vim.api.nvim_create_augroup("NvimTree", { clear = false }),
    })
  end

  configure_buffer_overlay(self)
  overlay_winnr = vim.api.nvim_open_win(overlay_bufnr, true, {
    col      = 1,
    row      = 0,
    relative = "cursor",
    width    = calculate_overlay_win_width(self),
    height   = 1,
    border   = "none",
    style    = "minimal",
  })

  if vim.fn.has("nvim-0.10") == 1 then
    vim.api.nvim_set_option_value("modifiable", true, { buf = overlay_bufnr })
  else
    vim.api.nvim_buf_set_option(overlay_bufnr, "modifiable", true) ---@diagnostic disable-line: deprecated
  end

  vim.api.nvim_buf_set_lines(overlay_bufnr, 0, -1, false, { self.filter })
  vim.cmd("startinsert")
  vim.api.nvim_win_set_cursor(overlay_winnr, { 1, #self.filter + 1 })
end

function LiveFilter:start_filtering()
  view.View.live_filter.prev_focused_node = self.explorer:get_node_at_cursor()
  self.filter = self.filter or ""

  self.explorer.renderer:draw()
  local row = require("nvim-tree.core").get_nodes_starting_line() - 1
  local col = #self.prefix > 0 and #self.prefix - 1 or 1
  view.set_cursor({ row, col })
  -- needs scheduling to let the cursor move before initializing the window
  vim.schedule(function()
    return create_overlay(self)
  end)
end

function LiveFilter:clear_filter()
  local node = self.explorer:get_node_at_cursor()
  local last_node = view.View.live_filter.prev_focused_node

  self.filter = nil
  reset_filter(self)
  self.explorer.renderer:draw()

  if node then
    utils.focus_file(node.absolute_path)
  elseif last_node then
    utils.focus_file(last_node.absolute_path)
  end
end

return LiveFilter
