local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {
  filter = nil,
}

local function redraw()
  require("nvim-tree.renderer").draw()
end

---@param node_ Node|nil
local function reset_filter(node_)
  node_ = node_ or require("nvim-tree.core").get_explorer()

  if node_ == nil then
    return
  end

  Iterator.builder(node_.nodes)
    :hidden()
    :applier(function(node)
      node.hidden = false
    end)
    :iterate()
end

local overlay_bufnr = nil
local overlay_winnr = nil

local function remove_overlay()
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
  overlay_bufnr = nil
  overlay_winnr = nil

  if M.filter == "" then
    M.clear_filter()
  end
end

---@param node Node
---@return boolean
local function matches(node)
  local path = node.absolute_path
  local name = vim.fn.fnamemodify(path, ":t")
  return vim.regex(M.filter):match_str(name) ~= nil
end

---@param node_ Node|nil
function M.apply_filter(node_)
  if not M.filter or M.filter == "" then
    reset_filter(node_)
    return
  end

  -- TODO(kiyan): this iterator cannot yet be refactored with the Iterator module
  -- since the node mapper is based on its children
  local function iterate(node)
    local filtered_nodes = 0
    local nodes = node.group_next and { node.group_next } or node.nodes

    if nodes then
      for _, n in pairs(nodes) do
        iterate(n)
        if n.hidden then
          filtered_nodes = filtered_nodes + 1
        end
      end
    end

    local has_nodes = nodes and (M.always_show_folders or #nodes > filtered_nodes)
    local ok, is_match = pcall(matches, node)
    node.hidden = not (has_nodes or (ok and is_match))
  end

  iterate(node_ or require("nvim-tree.core").get_explorer())
end

local function record_char()
  vim.schedule(function()
    M.filter = vim.api.nvim_buf_get_lines(overlay_bufnr, 0, -1, false)[1]
    M.apply_filter()
    redraw()
  end)
end

local function configure_buffer_overlay()
  overlay_bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_attach(overlay_bufnr, true, {
    on_lines = record_char,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = remove_overlay,
    once = true,
  })

  vim.api.nvim_buf_set_keymap(overlay_bufnr, "i", "<CR>", "<cmd>stopinsert<CR>", {})
end

---@return integer
local function calculate_overlay_win_width()
  local wininfo = vim.fn.getwininfo(view.get_winnr())[1]

  if wininfo then
    return wininfo.width - wininfo.textoff - #M.prefix
  end

  return 20
end

local function create_overlay()
  if view.View.float.enable then
    -- don't close nvim-tree float when focus is changed to filter window
    vim.api.nvim_clear_autocmds {
      event = "WinLeave",
      pattern = "NvimTree_*",
      group = vim.api.nvim_create_augroup("NvimTree", { clear = false }),
    }
  end

  configure_buffer_overlay()
  overlay_winnr = vim.api.nvim_open_win(overlay_bufnr, true, {
    col = 1,
    row = 0,
    relative = "cursor",
    width = calculate_overlay_win_width(),
    height = 1,
    border = "none",
    style = "minimal",
  })
  vim.api.nvim_buf_set_option(overlay_bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(overlay_bufnr, 0, -1, false, { M.filter })
  vim.cmd "startinsert"
  vim.api.nvim_win_set_cursor(overlay_winnr, { 1, #M.filter + 1 })
end

function M.start_filtering()
  view.View.live_filter.prev_focused_node = require("nvim-tree.lib").get_node_at_cursor()
  M.filter = M.filter or ""

  redraw()
  local row = require("nvim-tree.core").get_nodes_starting_line() - 1
  local col = #M.prefix > 0 and #M.prefix - 1 or 1
  view.set_cursor { row, col }
  -- needs scheduling to let the cursor move before initializing the window
  vim.schedule(create_overlay)
end

function M.clear_filter()
  local node = require("nvim-tree.lib").get_node_at_cursor()
  local last_node = view.View.live_filter.prev_focused_node

  M.filter = nil
  reset_filter()
  redraw()

  if node then
    utils.focus_file(node.absolute_path)
  elseif last_node then
    utils.focus_file(last_node.absolute_path)
  end
end

function M.setup(opts)
  M.prefix = opts.live_filter.prefix
  M.always_show_folders = opts.live_filter.always_show_folders
end

return M
