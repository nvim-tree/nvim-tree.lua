local M = {}

local api = vim.api
local fn = vim.fn

local function hide(win)
  if win then
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end
end

local function show()
  local line_nr = api.nvim_win_get_cursor(0)[1]
  if line_nr == 1 and require("nvim-tree.view").is_root_folder_visible() then
    return
  end
  if vim.wo.wrap then
    return
  end
  -- only work for left tree
  if vim.api.nvim_win_get_position(0)[2] ~= 0 then
    return
  end

  local line = fn.getline "."
  local leftcol = fn.winsaveview().leftcol
  -- hide full name if left column of node in nvim-tree win is not zero
  if leftcol ~= 0 then
    return
  end

  local width = fn.strdisplaywidth(fn.substitute(line, "[^[:print:]]*$", "", "g"))
  if width < fn.winwidth(0) then
    return
  end
  M.popup_win = api.nvim_open_win(api.nvim_create_buf(false, false), false, {
    relative = "win",
    bufpos = { fn.line "." - 2, 0 },
    width = math.min(width, vim.o.columns - 2),
    height = 1,
    noautocmd = true,
    style = "minimal",
  })

  local ns_id = api.nvim_get_namespaces()["NvimTreeHighlights"]
  local extmarks = api.nvim_buf_get_extmarks(0, ns_id, { line_nr - 1, 0 }, { line_nr - 1, -1 }, { details = 1 })
  api.nvim_win_call(M.popup_win, function()
    fn.setbufline("%", 1, line)
    for _, extmark in ipairs(extmarks) do
      local hl = extmark[4]
      api.nvim_buf_add_highlight(0, ns_id, hl.hl_group, 0, extmark[3], hl.end_col)
    end
    vim.cmd [[ setlocal nowrap cursorline noswapfile nobuflisted buftype=nofile bufhidden=hide ]]
  end)
end

M.setup = function(opts)
  M.config = opts.renderer
  if not M.config.full_name then
    return
  end

  local group = api.nvim_create_augroup("nvim_tree_floating_node", { clear = true })
  api.nvim_create_autocmd({ "BufLeave", "CursorMoved" }, {
    group = group,
    pattern = { "NvimTree_*" },
    callback = function()
      hide(M.popup_win)
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = group,
    pattern = { "NvimTree_*" },
    callback = function()
      show()
    end,
  })
end

return M
