local M = {
  config = nil,
  path = nil,
}

--- Write to log
--- @param typ as per config log.types
--- @param fmt for string.format
--- @param ... arguments for string.format
function M.raw(typ, fmt, ...)
  if not M.path or not M.config.types[typ] and not M.config.types.all then
    return
  end

  local line = string.format(fmt, ...)
  local file = io.open(M.path, "a")
  io.output(file)
  io.write(line)
  io.close(file)
end

-- Write to log with time and typ prefixed and a trailing newline
function M.line(typ, fmt, ...)
  if not M.path or not M.config.types[typ] and not M.config.types.all then
    return
  end

  M.raw(typ, string.format("[%s] [%s] %s\n", os.date("%H:%M:%S"), typ, fmt), ...)
end

function M.setup(opts)
  M.config = opts.log
  if M.config and M.config.enable and M.config.types then
	  M.path = string.format("%s/nvim-tree-%s-%s.log", vim.env.HOME, os.date("%H:%M:%S"), vim.env.USER)
  end
end

return M

