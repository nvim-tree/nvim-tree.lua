local view = require "nvim-tree.view"

local M = {
  -- one and only buf/win
  bufnr = nil,
  winnr = nil,
}

local function tidy_lhs(lhs)
  -- nvim_buf_get_keymap replaces leading "<" with "<lt>" e.g. "<lt>CTRL-v>"
  lhs = lhs:gsub("^<lt>", "<")

  -- shorten ctrls
  if lhs:lower():match "^<ctrl%-" then
    lhs = lhs:lower():gsub("^<ctrl%-", "<C%-")
  end

  -- uppercase ctrls
  if lhs:lower():match "^<c%-" then
    lhs = lhs:upper()
  end

  -- space is not escaped
  lhs = lhs:gsub(" ", "<Space>")

  return lhs
end

--- Remove prefix 'nvim-tree: '
--- Hardcoded to keep default_on_attach simple
--- @param desc string
--- @return string|nil
local function tidy_desc(desc)
  return desc and desc:gsub("^nvim%-tree: ", "") or ""
end

-- sort lhs roughly as per :help index
local PAT_MOUSE = "^<.*Mouse"
local PAT_CTRL = "^<C%-"
local PAT_SPECIAL = "^<.+"
local function sort_lhs(a, b)
  -- mouse last
  if a:match(PAT_MOUSE) and not b:match(PAT_MOUSE) then
    return false
  elseif not a:match(PAT_MOUSE) and b:match(PAT_MOUSE) then
    return true
  end

  -- ctrl first
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

  -- lowercase alpha characters only
  return a:gsub("[^a-zA-Z]", ""):lower() < b:gsub("[^a-zA-Z]", ""):lower()
end

function M.compute_lines()
  local help_lines = { "nvim-tree Mappings" }
  local help_hl = { { "NvimTreeRootFolder", 0, 0, #help_lines[1] } }

  local buf_keymaps = vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "")

  local lines = vim.tbl_map(function(bkm)
    return { lhs = tidy_lhs(bkm.lhs), desc = tidy_desc(bkm.desc) }
  end, buf_keymaps)

  table.sort(lines, function(a, b)
    return sort_lhs(a.lhs, b.lhs)
  end)

  local num = 0
  for _, p in pairs(lines) do
    num = num + 1
    local bind_string = string.format("%-5s %s", p.lhs, p.desc)
    local hl_len = math.max(5, string.len(p.lhs))
    table.insert(help_lines, bind_string)

    table.insert(help_hl, { "NvimTreeFolderName", num, 0, hl_len })

    table.insert(help_hl, { "NvimTreeFileRenamed", num, hl_len, -1 })
  end
  return help_lines, help_hl
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

  local lines, hl = M.compute_lines()

  -- calculate width
  local width = 1
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end

  -- create the buffer
  M.bufnr = vim.api.nvim_create_buf(false, true)

  -- populate it
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.bufnr, "modifiable", false)

  -- highlight it
  for _, data in ipairs(hl) do
    vim.api.nvim_buf_add_highlight(M.bufnr, -1, data[1], data[2], data[3], data[4])
  end

  -- open a very restricted window
  M.winnr = vim.api.nvim_open_win(M.bufnr, true, {
    relative = "editor",
    border = "rounded",
    width = width,
    height = #lines,
    row = 1,
    col = 1,
    style = "minimal",
    noautocmd = true,
  })

  -- style it a bit like the tree
  vim.wo[M.winnr].cursorline = view.View.winopts.cursorline

  -- close window and delete buffer on leave
  vim.api.nvim_create_autocmd("WinLeave", {
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

return M
