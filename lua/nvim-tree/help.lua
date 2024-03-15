local utils = require "nvim-tree.utils"
local keymap = require "nvim-tree.keymap"

local PAT_MOUSE = "^<.*Mouse"
local PAT_CTRL = "^<C%-"
local PAT_SPECIAL = "^<.+"

local WIN_HL = table.concat({
  "NormalFloat:NvimTreeNormalFloat",
  "WinSeparator:NvimTreeWinSeparator",
  "CursorLine:NvimTreeCursorLine",
}, ",")

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
---@param desc string
---@return string
local function tidy_desc(desc)
  return desc and desc:gsub("^nvim%-tree: ", "") or ""
end

--- sort vim command lhs roughly as per :help index
---@param a string
---@param b string
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
---@return table strings of text
---@return table arrays of arguments 3-6 for nvim_buf_add_highlight()
---@return number maximum length of text
local function compute()
  local head_lhs = "nvim-tree mappings"
  local head_rhs1 = "exit: q"

  local api = require "nvim-tree.api"
  local map = keymap.get_keymap()
  local exposed_apis = api.meta.get_exposed_apis()


  local mappings = vim.tbl_map(function(exposed_api)
    -- find all keybindings this api entry
    local assigned_keys = vim.tbl_filter(function(key)
      return key.callback == exposed_api.fn
    end, map)

    -- if no keybindings, we still want to show api entry
    if #assigned_keys == 0 then
      return { {
        lhs = " ",
        desc = exposed_api.description,
        group = exposed_api.group,
        api_path = exposed_api.api_path
      } }
    end

    -- show all keybindings for api entry
    return vim.tbl_map(function(key)
      return {
        lhs = tidy_lhs(key.lhs),
        desc = exposed_api.description,
        group = exposed_api.group,
        api_path = exposed_api.api_path,
      }
    end, assigned_keys)
  end, exposed_apis)

  -- since 1 api entry might have a few keybindings assigned, it needs to be flattened
  mappings = utils.flatten(mappings)
  local groups = utils.group_by(mappings, "group")

  -- transform dict into array
  local group_list = {}
  for group_name, group in pairs(groups) do
    table.insert(group_list, { name = group_name, group = group })
  end

  -- sort groups by group name
  table.sort(group_list, function (a, b)
    return a.name:lower() < b.name:lower()
  end)

  -- sort keybindings by description
  for _, group_item in ipairs(group_list) do
    table.sort(group_item.group, function(a, b)
      return a.desc:lower() < b.desc:lower()
    end)
  end

  -- longest lhs, description and api path
  local max_lhs = 0
  local max_desc = 0
  local max_api_path = 0
  for _, l in pairs(mappings) do
    max_lhs = math.max(#l.lhs, max_lhs)
    max_desc = math.max(#l.desc, max_desc)
    max_api_path = math.max(#l.api_path, max_api_path)
  end

  local width = max_lhs + max_desc + max_api_path + 3

  -- header text
  local lines = {
    utils.pad_end(head_lhs .. string.rep(" ", width - #head_lhs - #head_rhs1) .. head_rhs1, width),
    string.rep(" ", width),
  }

  -- header highlight, assume one character keys
  local hl = {
    { "NvimTreeFolderName", 0, 0,         #head_lhs },
    { "NvimTreeFolderName", 0, width - 1, width },
    { "NvimTreeFolderName", 1, width - 1, width },
  }

  -- mappings, left padded 1
  local i = 1
  for _, group_item in ipairs(group_list) do
    -- group name
    table.insert(lines, utils.pad_end(" " .. group_item.name, width))
    table.insert(hl, { "NvimTreeSymlink", i + 1, 1, #group_item.name + 1 })
    i = i + 1

    local fmt = string.format(" %%-%ds %%-%ds %%-%ds", max_lhs, max_desc, max_api_path)
    for _, l in ipairs(group_item.group) do
      -- format in left aligned columns
      local line = string.format(fmt, l.lhs, l.desc, l.api_path)
      table.insert(lines, line)

      -- highlight lhs
      table.insert(hl, { "NvimTreeFolderName", i + 1, 1, #l.lhs + 1 })

      -- highlight api path
      table.insert(hl, { "NvimTreeFolderName", i + 1, max_lhs + max_desc + 3, max_lhs + max_desc + #l.api_path + 3 })
      i = i + 1
    end

    -- empty line between groups
    table.insert(lines, string.rep(" ", width))
    i = i + 1
  end

  -- remove last empty line
  table.remove(lines, nil)

  return lines, hl, width
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

  -- text and highlight
  local lines, hl, width = compute()

  -- create the buffer
  M.bufnr = vim.api.nvim_create_buf(false, true)

  -- populate it
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.bufnr, "modifiable", false)

  -- highlight it
  for _, h in ipairs(hl) do
    vim.api.nvim_buf_add_highlight(M.bufnr, -1, h[1], h[2], h[3], h[4])
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
  vim.wo[M.winnr].winhl = WIN_HL
  vim.wo[M.winnr].cursorline = M.config.cursorline

  local keymaps = {
    q = { fn = close, desc = "nvim-tree: exit help" },
  }

  for k, v in pairs(keymaps) do
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
end

return M
