local M = {
  config = nil,
  path = nil,
}

--- Write to log file
--- @param typ string as per log.types config
--- @param fmt string for string.format
--- @param ... any arguments for string.format
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

--- Write to log file via M.line
--- START is prefixed
--- @return reltime to pass to profile_end
function M.profile_start(fmt, ...)
  M.line("profile", "START " .. (fmt or "???"), ...)
  return vim.fn.reltime()
end

--- Write to log file via M.line
--- END is prefixed and duration in seconds is suffixed
--- @param start reltime returned from profile_start
function M.profile_end(start, fmt, ...)
  local dur = vim.fn.reltimestr(vim.fn.reltime(start, vim.fn.reltime()))
  M.line("profile", "END   " .. (fmt or "???") .. "  " .. dur .. "s", ...)
end

-- Write to log file via M.raw
-- time and typ are prefixed and a trailing newline is added
function M.line(typ, fmt, ...)
  M.raw(typ, string.format("[%s] [%s] %s\n", os.date "%Y-%m-%d %H:%M:%S", typ, fmt), ...)
end

function M.setup(opts)
  M.config = opts.log
  if M.config and M.config.enable and M.config.types then
    M.path = string.format("%s/nvim-tree.log", vim.fn.stdpath "cache", os.date "%H:%M:%S", vim.env.USER)
    if M.config.truncate then
      os.remove(M.path)
    end
    print("nvim-tree.lua logging to " .. M.path)
  end
end

return M
