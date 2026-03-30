local config = require("nvim-tree.config")

---@alias devicons_get_icon fun(name: string, ext: string?, opts: table?): string?, string?
---@alias devicons_setup fun(opts: table?)

---@class (strict) DevIcons?
---@field setup devicons_setup
---@field get_icon devicons_get_icon
local devicons

--One shot lazy discovery and setup done
local initialized = false

local M = {}

---Wrapper around nvim-web-devicons, nils if devicons not available
---@type devicons_get_icon
function M.get_icon(name, ext, opts)
  if not initialized then
    M.initialize()
  end

  if devicons then
    return devicons.get_icon(name, ext, opts)
  else
    return nil, nil
  end
end

---Attempt to use nvim-web-devicons if present and enabled for file or folder
function M.initialize()
  if config.g.renderer.icons.show.file or config.g.renderer.icons.show.folder then
    local ok, di = pcall(require, "nvim-web-devicons")
    if ok then
      devicons = di --[[@as DevIcons]]

      -- does nothing if already called i.e. doesn't clobber previous user setup
      devicons.setup()
    end
  end
  initialized = true
end

return M
