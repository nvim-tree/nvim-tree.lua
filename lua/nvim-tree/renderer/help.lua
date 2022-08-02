local M = {}

local function tidy_lhs(lhs)
  -- nvim_buf_get_keymap replaces leading "<" with "<lt>" e.g. "<lt>CTRL-v>"
  lhs = lhs:gsub("^<lt>", "<")

  -- shorten ctrls
  if lhs:lower():match "^<ctrl%-" then
    lhs = lhs:lower():gsub("^<ctrl%-", "<C%-")
  end

  -- uppercase ctrls
  if lhs:match "^<C%-" then
    lhs = lhs:upper()
  end

  return lhs
end

local function shorten_lhs(lhs)
  return lhs
    :gsub("LeftMouse>$", "LM>")
    :gsub("RightMouse>$", "RM>")
    :gsub("MiddleMouse>$", "MM>")
    :gsub("ScrollWheelDown>$", "SD>")
    :gsub("ScrollWheelUp>$", "SU>")
    :gsub("ScrollWheelLeft>$", "SL>")
    :gsub("ScrollWheelRight>$", "SR>")
end

-- sort lhs roughly as per :help index
local PAT_MOUSE = "^<.*Mouse"
local PAT_CTRL = "^<C\\-"
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

  -- non-alpha next
  if a:match "^%a" and not b:match "^%a" then
    return false
  elseif not a:match "^%a" and b:match "^%a" then
    return true
  end

  return a < b
end

function M.compute_lines()
  local help_lines = { "HELP" }
  local help_hl = { { "NvimTreeRootFolder", 0, 0, #help_lines[1] } }

  local buf_keymaps = vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "")

  local lines = vim.tbl_map(function(bkm)
    return { lhs = tidy_lhs(bkm.lhs), desc = bkm.desc }
  end, buf_keymaps)

  table.sort(lines, function(a, b)
    return sort_lhs(a.lhs, b.lhs)
  end)

  for _, p in pairs(lines) do
    p.lhs = shorten_lhs(p.lhs)
  end

  local num = 0
  for _, p in pairs(lines) do
    num = num + 1
    local bind_string = string.format("%-6.6s %s", shorten_lhs(p.lhs), p.desc)
    table.insert(help_lines, bind_string)

    table.insert(help_hl, { "NvimTreeFolderName", num, 0, 6 })

    table.insert(help_hl, { "NvimTreeFileRenamed", num, 6, -1 })
  end
  return help_lines, help_hl
end

return M
