local appearance = require "nvim-tree.appearance"

local M = {}

---@class HighlightDisplay for :NvimTreeHiTest
---@field group string nvim-tree highlight group name
---@field links string link chain to a concretely defined group
---@field def string :hi concrete definition after following any links
local HighlightDisplay = {}

---@param group string nvim-tree highlight group
---@return HighlightDisplay
function HighlightDisplay:new(group)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.group = group
  local concrete = o.group

  -- maybe follow links
  local links = {}
  local link = vim.api.nvim_get_hl(0, { name = o.group }).link
  while link do
    table.insert(links, link)
    concrete = link
    link = vim.api.nvim_get_hl(0, { name = link }).link
  end
  o.links = table.concat(links, " ")

  -- concrete definition
  local ok, res = pcall(vim.api.nvim_cmd, { cmd = "highlight", args = { concrete } }, { output = true })
  if ok and type(res) == "string" then
    o.def = res:gsub(".*xxx *", "")
  else
    o.def = ""
  end

  return o
end

function HighlightDisplay:render(bufnr, fmt, l)
  local text = string.format(fmt, self.group, self.links, self.def)

  vim.api.nvim_buf_set_lines(bufnr, l, -1, true, { text })
  vim.api.nvim_buf_add_highlight(bufnr, -1, self.group, l, 0, #self.group)
end

---Run a test similar to :so $VIMRUNTIME/syntax/hitest.vim
---Display all nvim-tree highlight groups, their link chain and actual definition
function M.hi_test()
  local displays = {}
  local max_group_len = 0
  local max_links_len = 0

  -- build all highlight groups, name only
  for _, highlight_group in ipairs(appearance.HIGHLIGHT_GROUPS) do
    local display = HighlightDisplay:new(highlight_group.group)
    table.insert(displays, display)
    max_group_len = math.max(max_group_len, #display.group)
    max_links_len = math.max(max_links_len, #display.links)
  end

  -- create a buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- render and highlight
  local l = 0
  local fmt = string.format("%%-%d.%ds %%-%d.%ds %%s", max_group_len, max_group_len, max_links_len, max_links_len)
  for _, display in ipairs(displays) do
    display:render(bufnr, fmt, l)
    l = l + 1
  end

  -- finalise and focus the buffer
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.cmd.buffer(bufnr)
end

return M
