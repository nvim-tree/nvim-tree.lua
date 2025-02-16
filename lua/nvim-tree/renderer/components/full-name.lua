local M = {}

local utils = require("nvim-tree.utils")

local function hide(win)
  if win then
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
end

-- reduce signcolumn/foldcolumn from window width
local function effective_win_width()
  local win_width = vim.fn.winwidth(0)

  -- return zero if the window cannot be found
  local win_id = vim.fn.win_getid()

  if win_id == 0 then
    return win_width
  end

  -- if the window does not exist the result is an empty list
  local win_info = vim.fn.getwininfo(win_id)

  -- check if result table is empty
  if next(win_info) == nil then
    return win_width
  end

  return win_width - win_info[1].textoff
end

local function show()
  local line_nr = vim.api.nvim_win_get_cursor(0)[1]
  if vim.wo.wrap then
    return
  end
  -- only work for left tree
  if vim.api.nvim_win_get_position(0)[2] ~= 0 then
    return
  end

  local line = vim.fn.getline(".")
  local leftcol = vim.fn.winsaveview().leftcol
  -- hide full name if left column of node in nvim-tree win is not zero
  if leftcol ~= 0 then
    return
  end

  local text_width = vim.fn.strdisplaywidth(vim.fn.substitute(line, "[^[:print:]]*$", "", "g"))
  local win_width = effective_win_width()

  if text_width < win_width then
    return
  end

  M.popup_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, false), false, {
    relative  = "win",
    row       = 0,
    bufpos    = { vim.api.nvim_win_get_cursor(0)[1] - 1, 0 },
    width     = math.min(text_width, vim.o.columns - 2),
    height    = 1,
    noautocmd = true,
    style     = "minimal",
  })

  local ns_id = vim.api.nvim_get_namespaces()["NvimTreeHighlights"]
  local extmarks = vim.api.nvim_buf_get_extmarks(0, ns_id, { line_nr - 1, 0 }, { line_nr - 1, -1 }, { details = true })
  vim.api.nvim_win_call(M.popup_win, function()
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { line })
    for _, extmark in ipairs(extmarks) do
      -- nvim 0.10 luadoc is incorrect: vim.api.keyset.get_extmark_item is missing the extmark_id at the start

      ---@cast extmark table
      ---@type integer
      local col = extmark[3]
      ---@type vim.api.keyset.extmark_details
      local details = extmark[4]

      if type(details) == "table" then
        if vim.fn.has("nvim-0.11") == 1 and vim.hl and vim.hl.range then
          vim.hl.range(0, ns_id, details.hl_group, { 0, col }, { 0, details.end_col, }, {})
        else
          vim.api.nvim_buf_add_highlight(0, ns_id, details.hl_group, 0, col, details.end_col) ---@diagnostic disable-line: deprecated
        end
      end
    end
    vim.cmd([[ setlocal nowrap cursorline noswapfile nobuflisted buftype=nofile bufhidden=wipe ]])
  end)
end

M.setup = function(opts)
  M.config = opts.renderer
  if not M.config.full_name then
    return
  end

  local group = vim.api.nvim_create_augroup("nvim_tree_floating_node", { clear = true })
  vim.api.nvim_create_autocmd({ "BufLeave", "CursorMoved" }, {
    group = group,
    pattern = { "NvimTree_*" },
    callback = function()
      if utils.is_nvim_tree_buf(0) then
        hide(M.popup_win)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = group,
    pattern = { "NvimTree_*" },
    callback = function()
      if utils.is_nvim_tree_buf(0) then
        show()
      end
    end,
  })
end

return M
