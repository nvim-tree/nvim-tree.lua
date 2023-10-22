local modified = require "nvim-tree.modified"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION

local M = {
  icon = nil,
  hl_pos = HL_POSITION.none,
}

---modified icon if modified
---@param node table
---@return HighlightedString|nil modified icon
function M.get_icon(node)
  if M.icon and modified.is_modified(node) then
    return M.icon
  end
end

---Diagnostics highlight group and position when highlight_diagnostics.
---@param node table
---@return HL_POSITION position none when no status
---@return string|nil group only when status
function M.get_highlight(node)
  if M.hl_pos == HL_POSITION.none or not modified.is_modified(node) then
    return HL_POSITION.none, nil
  end

  if node.nodes then
    return M.hl_pos, "NvimTreeModifiedFolderHL"
  else
    return M.hl_pos, "NvimTreeModifiedFileHL"
  end
end

function M.setup(opts)
  if not opts.modified.enable then
    return
  end

  M.hl_pos = HL_POSITION[opts.renderer.highlight_modified] or HL_POSITION.none

  if opts.renderer.icons.show.modified then
    M.icon = {
      str = opts.renderer.icons.glyphs.modified,
      hl = { "NvimTreeModifiedIcon" },
    }
    vim.fn.sign_define(M.icon.hl[1], {
      text = M.icon.str,
      texthl = M.icon.hl[1],
    })
  end
end

return M
