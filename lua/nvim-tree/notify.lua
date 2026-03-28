local config = require("nvim-tree.config")

local M = {}

local title_support
---@return boolean
function M.supports_title()
  if title_support == nil then
    title_support = (package.loaded.notify and (vim.notify == require("notify") or vim.notify == require("notify").notify))
      or (package.loaded.noice and (vim.notify == require("noice").notify or vim.notify == require("noice.source.notify").notify))
      or (package.loaded.notifier and require("notifier.config").has_component("nvim"))
      or false
  end

  return title_support
end

local modes = {
  { name = "trace", level = vim.log.levels.TRACE },
  { name = "debug", level = vim.log.levels.DEBUG },
  { name = "info",  level = vim.log.levels.INFO },
  { name = "warn",  level = vim.log.levels.WARN },
  { name = "error", level = vim.log.levels.ERROR },
}

do
  ---@param level vim.log.levels
  ---@param msg string
  local dispatch = function(level, msg)
    local threshold = config.g and config.g.notify.threshold or config.d.notify.threshold
    if level < threshold or not msg then
      return
    end

    vim.schedule(function()
      if not M.supports_title() then
        -- add title to the message, with a newline if the message is multiline
        msg = string.format("[NvimTree]%s%s", (msg:match("\n") and "\n" or " "), msg)
      end

      vim.notify(msg, level, { title = "NvimTree" })
    end)
  end

  for _, x in ipairs(modes) do
    M[x.name] = function(msg)
      return dispatch(x.level, msg)
    end
  end
end

---@param path string
---@return string
function M.render_path(path)
  if config.g and config.g.notify.absolute_path then
    return path
  else
    return vim.fn.fnamemodify(path .. "/", ":h:t")
  end
end

return M
