local core = require("nvim-tree.core")

local M = {}

---Resize the tree, persisting the new size.
---@param opts ApiTreeResizeOpts|nil
function M.fn(opts)
  local explorer = core.get_explorer()
  if not explorer then
    return
  end

  if opts == nil then
    -- reset to config values
    explorer.view:configure_width()
    explorer.view:resize()
    return
  end

  local options = opts or {}
  local width_cfg = options.width

  if width_cfg ~= nil then
    explorer.view:configure_width(width_cfg)
    explorer.view:resize()
    return
  end

  if not explorer.view:is_width_determined() then
    -- {absolute} and {relative} do nothing when {width} is a function.
    return
  end

  local absolute = options.absolute
  if type(absolute) == "number" then
    explorer.view:resize(absolute)
    return
  end

  local relative = options.relative
  if type(relative) == "number" then
    local relative_size = tostring(relative)
    if relative > 0 then
      relative_size = "+" .. relative_size
    end

    explorer.view:resize(relative_size)
    return
  end
end

function M.setup(opts)
  M.config = opts or {}
end

return M
