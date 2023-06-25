local M = {}

local config = {
  threshold = vim.log.levels.INFO,
  absolute_path = true,
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
      vim.notify(msg, level, { title = "NvimTree" })
    end)
  end

  for _, x in ipairs(modes) do
    M[x.name] = function(msg)
      return dispatch(x.level, msg)
    end
  end
end

function M.render_path(path)
  if config.absolute_path then
    return path
  else
    return vim.fn.fnamemodify(path .. "/", ":h:t")
  end
end

function M.setup(opts)
  opts = opts or {}
  config.threshold = opts.notify.threshold or vim.log.levels.INFO
  config.absolute_path = opts.notify.absolute_path
end

return M
