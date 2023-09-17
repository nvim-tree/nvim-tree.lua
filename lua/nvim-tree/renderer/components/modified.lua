local modified = require "nvim-tree.modified"

local M = {}

local HIGHLIGHT = "NvimTreeModifiedFile"

---return modified icon if node is modified, otherwise return empty string
---@param node table
---@return HighlightedString|nil modified icon
function M.get_icon(node)
  if not modified.is_modified(node) or not M.show_icon then
    return nil
  end

  return { str = M.icon, hl = { HIGHLIGHT } }
end

function M.setup_signs()
  vim.fn.sign_define(HIGHLIGHT, { text = M.icon, texthl = HIGHLIGHT })
end

---@param node table
---@return string|nil
function M.get_highlight(node)
  if not modified.is_modified(node) then
    return nil
  end

  return HIGHLIGHT
end

function M.setup(opts)
  M.icon = opts.renderer.icons.glyphs.modified
  M.show_icon = opts.renderer.icons.show.modified

  if opts.renderer.icons.modified_placement == "signcolumn" then
    M.setup_signs()
  end
end

return M
