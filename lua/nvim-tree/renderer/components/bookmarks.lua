local marks = require "nvim-tree.marks"

local M = {}

local ICON = {}

---bookmark text highlight group if marked
---@param node table
---@return string|nil group
function M.get_highlight(node)
  if M.config.renderer.highlight_bookmarks and marks.get_mark(node) then
    return "NvimTreeBookmarkText"
  end
end

---bookmark icon if marked
---@param node table
---@return HighlightedString|nil bookmark icon
function M.get_icon(node)
  if M.config.renderer.icons.show.bookmarks and marks.get_mark(node) then
    return ICON
  end
end

function M.setup(opts)
  M.config = {
    renderer = opts.renderer,
  }

  ICON = {
    str = opts.renderer.icons.glyphs.bookmark,
    hl = { "NvimTreeBookmark" },
  }

  vim.fn.sign_define(ICON.hl[1], { text = ICON.str, texthl = ICON.hl[1] })
end

return M
