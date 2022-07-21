local a = vim.api

local view = require "nvim-tree.view"
local Iterator = require "nvim-tree.iterators.node-iterator"
local core = function()
  return require "nvim-tree.core"
end

local M = {
  filter = nil,
  filter_type = nil,
}

local function redraw()
  require("nvim-tree.renderer").draw()
end

local function reset_filter(node_)
  node_ = node_ or TreeExplorer
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
  a.nvim_win_close(overlay_winnr, { force = true })
  overlay_bufnr = nil
  overlay_winnr = nil

  if M.filter == "" then
    M.clear_filter()
  end
end

local function load_matcher()
  if M.filter_type == "Input" then
    return function(node)
      local path = node.absolute_path
      local name = vim.fn.fnamemodify(path, ":t")
      return vim.regex(M.filter):match_str(name) ~= nil
    end
  elseif M.filter_type == "Buffer" then
    local buffers = vim.tbl_map(
      function(buf)
        return vim.api.nvim_buf_get_name(buf)
      end,
      vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_loaded(buf)
      end, vim.api.nvim_list_bufs())
    )
    return function(node)
      return vim.tbl_contains(buffers, node.absolute_path)
    end
  else
    return function()
      return true
    end
  end
end

function M.apply_filter(node_)
  if not M.filter or M.filter == "" then
    reset_filter(node_)
    return
  end

  local matches = load_matcher()

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
    node.hidden = not (has_nodes or matches(node))
  end

  iterate(node_ or TreeExplorer)
end

local function record_char()
  vim.schedule(function()
    M.filter = a.nvim_buf_get_lines(overlay_bufnr, 0, -1, false)[1]
    M.apply_filter()
    redraw()
  end)
end

local function configure_buffer_overlay()
  overlay_bufnr = a.nvim_create_buf(false, true)

  a.nvim_buf_attach(overlay_bufnr, true, {
    on_lines = record_char,
  })

  a.nvim_create_autocmd("InsertLeave", {
    callback = remove_overlay,
    once = true,
  })

  a.nvim_buf_set_keymap(overlay_bufnr, "i", "<CR>", "<cmd>stopinsert<CR>", {})
end

local function create_overlay()
  configure_buffer_overlay()
  overlay_winnr = a.nvim_open_win(overlay_bufnr, true, {
    col = 1,
    row = 0,
    relative = "cursor",
    width = math.max(20, a.nvim_win_get_width(view.get_winnr()) - #M.prefix - 2),
    height = 1,
    border = "none",
    style = "minimal",
  })
  a.nvim_buf_set_option(overlay_bufnr, "modifiable", true)
  a.nvim_buf_set_lines(overlay_bufnr, 0, -1, false, { M.filter })
  vim.cmd "startinsert"
  a.nvim_win_set_cursor(overlay_winnr, { 1, #M.filter + 1 })
end

function M.start_filtering(filter_type)
  M.filter_type = filter_type or "Input"
  M.filter = M.filter_type == "Input" and (M.filter or "") or "Buffer"

  if M.filter_type == "Input" then
    redraw()
    local row = core().get_nodes_starting_line() - 1
    local col = #M.prefix > 0 and #M.prefix - 1 or 1
    view.set_cursor { row, col }
    -- needs scheduling to let the cursor move before initializing the window
    vim.schedule(create_overlay)
  elseif M.filter_type == "Buffer" then
    M.apply_filter(core().get_explorer())
    redraw()
    M.BUFFER_AU_ID = vim.api.nvim_create_autocmd({ "BufNewFile", "BufDelete" }, {
      group = vim.api.nvim_create_augroup("NvimTreeLiveFilterBuffer", { clear = true }),
      callback = function()
        M.apply_filter(core().get_explorer())
        redraw()
      end,
    })
  end
end

function M.clear_filter()
  if M.BUFFER_AU_ID ~= nil then
    vim.api.nvim_del_autocmd(M.BUFFER_AU_ID)
    M.BUFFER_AU_ID = nil
  end
  M.filter = nil
  M.filter_type = nil
  reset_filter()
  redraw()
end

function M.setup(opts)
  M.prefix = opts.live_filter.prefix
  M.always_show_folders = opts.live_filter.always_show_folders
end

return M
