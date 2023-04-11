local M = {}

local default_handler = function(msg, level, opts)
  vim.notify(string.format("[%s] %s", opts.title, vim.inspect(msg)), level)
end

local config = {
  threshold = vim.log.levels.INFO,
  handler = default_handler,
}

local modes = {
  { name = "trace", level = vim.log.levels.TRACE },
  { name = "debug", level = vim.log.levels.DEBUG },
  { name = "info", level = vim.log.levels.INFO },
  { name = "warn", level = vim.log.levels.WARN },
  { name = "error", level = vim.log.levels.ERROR },
}

do
  local dispatch = function(level, msg)
    if level < config.threshold then
      return
    end

    vim.schedule(function()
      config.handler(msg, level, { title = "NvimTree" })
    end)
  end

  for _, x in ipairs(modes) do
    M[x.name] = function(msg)
      return dispatch(x.level, msg)
    end
  end
end

function M.setup(opts)
  opts = opts or {}
  config.threshold = opts.notify.threshold or vim.log.levels.INFO
  if type(opts.notify.handler) == "function" then
    config.handler = opts.notify.handler
  end
end

return M
