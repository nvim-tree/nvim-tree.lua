local marks = require "nvim-tree.marks"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION

local M = {
  ICON = {},
  hl_pos = HL_POSITION.none,
}

---Bookmark highlight group and position when highlight_bookmark.
---@param node table
---@return HL_POSITION position none when clipboard empty
---@return string|nil group only when node present in clipboard
function M.get_highlight(node)
  if M.hl_pos == HL_POSITION.none then
    return HL_POSITION.none, nil
  end

  local mark = marks.get_mark(node)
  if mark then
    return M.hl_pos, "NvimTreeBookmarkHL"
  else
    return HL_POSITION.none, nil
  end
end

---bookmark icon if marked
---@param node table
---@return HighlightedString|nil bookmark icon
function M.get_icon(node)
  if M.config.renderer.icons.show.bookmarks and marks.get_mark(node) then
    return M.ICON
  end
end

function M.setup(opts)
  M.config = {
    renderer = opts.renderer,
  }

  M.hl_pos = HL_POSITION[opts.renderer.highlight_bookmarks] or HL_POSITION.none

  M.ICON = {
    str = opts.renderer.icons.glyphs.bookmark,
    hl = { "NvimTreeBookmark" },
  }

  vim.fn.sign_define(M.ICON.hl[1], { text = M.ICON.str, texthl = M.ICON.hl[1] })
end

return M
