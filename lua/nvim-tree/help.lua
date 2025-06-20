local appearance = require("nvim-tree.appearance")
local keymap = require("nvim-tree.keymap")
local api = {} -- circular dependency

local PAT_MOUSE = "^<.*Mouse"
local PAT_CTRL = "^<C%-"
local PAT_SPECIAL = "^<.+"

local namespace_help_id = vim.api.nvim_create_namespace("NvimTreeHelp")

local M = {
  config = {},

  -- one and only buf/win
  bufnr = nil,
  winnr = nil,
}

--- Shorten and normalise a vim command lhs
---@param lhs string
---@return string
local function tidy_lhs(lhs)
  -- nvim_buf_get_keymap replaces leading "<" with "<lt>" e.g. "<lt>CTRL-v>"
  lhs = lhs:gsub("^<lt>", "<")

  -- shorten ctrls
  if lhs:lower():match("^<ctrl%-") then
    lhs = lhs:lower():gsub("^<ctrl%-", "<C%-")
  end

  -- uppercase ctrls
  if lhs:lower():match("^<c%-") then
    lhs = lhs:upper()
  end

  -- space is not escaped
  lhs = lhs:gsub(" ", "<Space>")

  return lhs
end

--- Remove prefix 'nvim-tree: '
--- Hardcoded to keep default_on_attach simple
---@param desc string
---@return string
local function tidy_desc(desc)
  return desc and desc:gsub("^nvim%-tree: ", "") or ""
end

--- sort vim command lhs roughly as per :help index
---@param a string
---@param b string
---@return boolean
local function sort_lhs(a, b)
  -- mouse first
  if a:match(PAT_MOUSE) and not b:match(PAT_MOUSE) then
    return true
  elseif not a:match(PAT_MOUSE) and b:match(PAT_MOUSE) then
    return false
  end

  -- ctrl next
  if a:match(PAT_CTRL) and not b:match(PAT_CTRL) then
    return true
  elseif not a:match(PAT_CTRL) and b:match(PAT_CTRL) then
    return false
  end

  -- special next
  if a:match(PAT_SPECIAL) and not b:match(PAT_SPECIAL) then
    return true
  elseif not a:match(PAT_SPECIAL) and b:match(PAT_SPECIAL) then
    return false
  end

  -- remainder alpha
  return a:gsub("[^a-zA-Z]", "") < b:gsub("[^a-zA-Z]", "")
end

--- Compute all lines for the buffer
---@param map table keymap.get_keymap
---@return string[] lines of text
---@return HighlightRangeArgs[] hl_range_args for lines
---@return number maximum length of text
local function compute(map)
  local head_lhs = "nvim-tree mappings"
  local head_rhs1 = "exit: q"
  local head_rhs2 = string.format("sort by %s: s", M.config.sort_by == "key" and "description" or "keymap")

  -- formatted lhs and desc from active keymap
  local mappings = vim.tbl_map(function(m)
    return { lhs = tidy_lhs(m.lhs), desc = tidy_desc(m.desc) }
  end, map)

  -- sorter function for mappings
  local sort_fn

  if M.config.sort_by == "desc" then
    sort_fn = function(a, b)
      return a.desc:lower() < b.desc:lower()
    end
  else
    -- by default sort roughly by lhs
    sort_fn = function(a, b)
      return sort_lhs(a.lhs, b.lhs)
    end
  end

  table.sort(mappings, sort_fn)

  -- longest lhs and description
  local max_lhs = 0
  local max_desc = 0
  for _, l in pairs(mappings) do
    max_lhs = math.max(#l.lhs, max_lhs)
    max_desc = math.max(#l.desc, max_desc)
  end

  -- increase desc if lines are shorter than the header
  max_desc = math.max(max_desc, #head_lhs + #head_rhs1 - max_lhs)

  -- header text, not padded
  local lines = {
    head_lhs .. string.rep(" ", max_desc + max_lhs - #head_lhs - #head_rhs1 + 2) .. head_rhs1,
    string.rep(" ", max_desc + max_lhs - #head_rhs2 + 2) .. head_rhs2,
  }
  local width = #lines[1]

  -- header highlight, assume one character keys
  local hl_range_args = {
    { higroup = "NvimTreeFolderName", start = { 0, 0, },         finish = { 0, #head_lhs, }, },
    { higroup = "NvimTreeFolderName", start = { 0, width - 1, }, finish = { 0, width, }, },
    { higroup = "NvimTreeFolderName", start = { 1, width - 1, }, finish = { 1, width, }, },
  }

  -- mappings, left padded 1
  local fmt = string.format(" %%-%ds %%-%ds", max_lhs, max_desc)
  for i, l in ipairs(mappings) do
    -- format in left aligned columns
    local line = string.format(fmt, l.lhs, l.desc)
    table.insert(lines, line)
    width = math.max(#line, width)

    -- highlight lhs
    table.insert(hl_range_args, { higroup = "NvimTreeFolderName", start = { i + 1, 1, }, finish = { i + 1, #l.lhs + 1, }, })
  end

  return lines, hl_range_args, width
end

--- close the window and delete the buffer, if they exist
local function close()
  if M.winnr then
    vim.api.nvim_win_close(M.winnr, true)
    M.winnr = nil
  end
  if M.bufnr then
    vim.api.nvim_buf_delete(M.bufnr, { force = true })
    M.bufnr = nil
  end
end

--- open a new window and buffer
local function open()
  -- close existing, shouldn't be necessary
  close()

  -- fetch all mappings
  local map = keymap.get_keymap()

  -- text and highlight
  local lines, hl_range_args, width = compute(map)

  -- create the buffer
  M.bufnr = vim.api.nvim_create_buf(false, true)

  -- populate it
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, lines)

  if vim.fn.has("nvim-0.10") == 1 then
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.bufnr })
  else
    vim.api.nvim_buf_set_option(M.bufnr, "modifiable", false) ---@diagnostic disable-line: deprecated
  end

  -- highlight it
  for _, args in ipairs(hl_range_args) do
    if vim.fn.has("nvim-0.11") == 1 and vim.hl and vim.hl.range then
      vim.hl.range(M.bufnr, namespace_help_id, args.higroup, args.start, args.finish, {})
    else
      vim.api.nvim_buf_add_highlight(M.bufnr, -1, args.higroup, args.start[1], args.start[2], args.finish[2]) ---@diagnostic disable-line: deprecated
    end
  end

  -- open a very restricted window
  M.winnr = vim.api.nvim_open_win(M.bufnr, true, {
    relative = "editor",
    border = "single",
    width = width,
    height = #lines,
    row = 1,
    col = 0,
    style = "minimal",
    noautocmd = true,
  })

  -- style it a bit like the tree
  vim.wo[M.winnr].winhl = appearance.WIN_HL_HELP
  vim.wo[M.winnr].cursorline = M.config.cursorline

  local function toggle_sort()
    M.config.sort_by = (M.config.sort_by == "desc") and "key" or "desc"
    open()
  end

  -- hardcoded
  local help_keymaps = {
    q = { fn = close, desc = "nvim-tree: exit help" },
    ["<Esc>"] = { fn = close, desc = "nvim-tree: exit help" }, -- hidden
    s = { fn = toggle_sort, desc = "nvim-tree: toggle sorting method" },
  }

  -- api help binding closes
  for _, m in ipairs(map) do
    if m.callback == api.tree.toggle_help then
      help_keymaps[m.lhs] = { fn = close, desc = "nvim-tree: exit help" }
    end
  end

  for k, v in pairs(help_keymaps) do
    vim.keymap.set("n", k, v.fn, {
      desc = v.desc,
      buffer = M.bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    })
  end

  -- close window and delete buffer on leave
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = M.bufnr,
    once = true,
    callback = close,
  })
end

function M.toggle()
  if M.winnr or M.bufnr then
    close()
  else
    open()
  end
end

function M.setup(opts)
  M.config.cursorline = opts.view.cursorline
  M.config.sort_by = opts.help.sort_by

  api = require("nvim-tree.api")
end

return M
