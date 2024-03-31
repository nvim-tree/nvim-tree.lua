local appearance = require "nvim-tree.appearance"

-- others with name and links less than this arbitrary value are short
local SHORT_LEN = 50

local M = {}

---@class HighlightDisplay for :NvimTreeHiTest
---@field group string nvim-tree highlight group name
---@field links string link chain to a concretely defined group
---@field def string :hi concrete definition after following any links
local HighlightDisplay = {}

---@param group string nvim-tree highlight group name
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

---Render one group.
---@param bufnr number to render in
---@param fmt string format string for group, links, def
---@param l number line number to render at
---@return number l next line number
function HighlightDisplay:render(bufnr, fmt, l)
  local text = string.format(fmt, self.group, self.links, self.def)

  vim.api.nvim_buf_set_lines(bufnr, l, -1, true, { text })
  vim.api.nvim_buf_add_highlight(bufnr, -1, self.group, l, 0, #self.group)

  return l + 1
end

---Render many groups.
---@param header string before with underline line
---@param displays HighlightDisplay[] highlight group
---@param bufnr number to render in
---@param l number line number to start at
---@return number l next line number
local function render_displays(header, displays, bufnr, l)
  local max_group_len = 0
  local max_links_len = 0

  -- build all highlight groups, using name only
  for _, display in ipairs(displays) do
    max_group_len = math.max(max_group_len, #display.group)
    max_links_len = math.max(max_links_len, #display.links)
  end

  -- header
  vim.api.nvim_buf_set_lines(bufnr, l, -1, true, { header, (header:gsub(".", "-")) })
  l = l + 2

  -- render and highlight
  local fmt = string.format("%%-%d.%ds %%-%d.%ds %%s", max_group_len, max_group_len, max_links_len, max_links_len)
  for _, display in ipairs(displays) do
    l = display:render(bufnr, fmt, l)
  end

  return l
end

---Run a test similar to :so $VIMRUNTIME/syntax/hitest.vim
---Display all nvim-tree and neovim highlight groups, their link chain and actual definition
function M.hi_test()
  -- create a buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  local l = 0

  -- nvim-tree groups, ordered
  local displays = {}
  for _, highlight_group in ipairs(appearance.HIGHLIGHT_GROUPS) do
    local display = HighlightDisplay:new(highlight_group.group)
    table.insert(displays, display)
  end
  l = render_displays("nvim-tree", displays, bufnr, l)

  vim.api.nvim_buf_set_lines(bufnr, l, -1, true, { "" })
  l = l + 1

  -- built in groups, ordered opaquely by nvim
  local displays_short, displays_long = {}, {}
  local ok, out = pcall(vim.api.nvim_cmd, { cmd = "highlight" }, { output = true })
  if ok then
    for group in string.gmatch(out, "(%w*)%s+xxx") do
      if group:find("NvimTree", 1, true) ~= 1 then
        local display = HighlightDisplay:new(group)
        if #display.group + #display.links > SHORT_LEN then
          table.insert(displays_long, display)
        else
          table.insert(displays_short, display)
        end
      end
    end
  end

  -- short ones first
  l = render_displays("other, short", displays_short, bufnr, l)
  vim.api.nvim_buf_set_lines(bufnr, l, -1, true, { "" })
  l = l + 1

  -- long
  render_displays("other, long", displays_long, bufnr, l)

  -- finalise and focus the buffer
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.cmd.buffer(bufnr)
end

return M
