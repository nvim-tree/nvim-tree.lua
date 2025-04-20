local view = require("nvim-tree.view")

local M = {}

---Resize the tree, persisting the new size.
---@param opts ApiTreeResizeOpts|nil
function M.fn(opts)
  if opts == nil then
    -- reset to config values
    view.View:configure_width()
    view.View:resize()
    return
  end

  local options = opts or {}
  local width_cfg = options.width

  if width_cfg ~= nil then
    view.View:configure_width(width_cfg)
    view.View:resize()
    return
  end

  if not view.View:is_width_determined() then
    -- {absolute} and {relative} do nothing when {width} is a function.
    return
  end

  local absolute = options.absolute
  if type(absolute) == "number" then
    view.View:resize(absolute)
    return
  end

  local relative = options.relative
  if type(relative) == "number" then
    local relative_size = tostring(relative)
    if relative > 0 then
      relative_size = "+" .. relative_size
    end

    view.View:resize(relative_size)
    return
  end
end

function M.setup(opts)
  M.config = opts or {}
end

return M
