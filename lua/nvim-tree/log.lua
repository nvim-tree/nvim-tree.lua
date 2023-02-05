local M = {
  config = nil,
  path = nil,
}

--- Write to log file
--- @param typ string as per log.types config
--- @param fmt string for string.format
--- @vararg any arguments for string.format
function M.raw(typ, fmt, ...)
  if not M.enabled(typ) then
    return
  end

  local line = string.format(fmt, ...)
  local file = io.open(M.path, "a")
  if file then
    io.output(file)
    io.write(line)
    io.close(file)
  end
end

--- Write profile start to log file
--- START is prefixed
--- @param fmt string for string.format
--- @vararg any arguments for string.format
--- @return number nanos to pass to profile_end
function M.profile_start(fmt, ...)
  if M.enabled "profile" then
    M.line("profile", "START " .. (fmt or "???"), ...)
    return vim.loop.hrtime()
  else
    return 0
  end
end

--- Write profile end to log file
--- END is prefixed and duration in seconds is suffixed
--- @param start number nanos returned from profile_start
--- @param fmt string for string.format
--- @vararg any arguments for string.format
function M.profile_end(start, fmt, ...)
  if M.enabled "profile" then
    local millis = start and math.modf((vim.loop.hrtime() - start) / 1000000) or -1
    M.line("profile", "END   " .. (fmt or "???") .. "  " .. millis .. "ms", ...)
  end
end

--- Write to log file
--- time and typ are prefixed and a trailing newline is added
--- @param typ string as per log.types config
--- @param fmt string for string.format
--- @vararg any arguments for string.format
function M.line(typ, fmt, ...)
  if M.enabled(typ) then
    M.raw(typ, string.format("[%s] [%s] %s\n", os.date "%Y-%m-%d %H:%M:%S", typ, fmt), ...)
  end
end

--- Logging is enabled for typ or all
--- @param typ string as per log.types config
--- @return boolean
function M.enabled(typ)
  return M.path ~= nil and (M.config.types[typ] or M.config.types.all)
end

function M.setup(opts)
  M.config = opts.log
  if M.config and M.config.enable and M.config.types then
    M.path = string.format("%s/nvim-tree.log", vim.fn.stdpath "cache", os.date "%H:%M:%S", vim.env.USER)
    if M.config.truncate then
      os.remove(M.path)
    end
    require("nvim-tree.notify").debug("nvim-tree.lua logging to " .. M.path)
  end
end

return M
