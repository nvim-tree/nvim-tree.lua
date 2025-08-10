---@alias LogTypes "all" | "config" | "copy_paste" | "dev" | "diagnostics" | "git" | "profile" | "watcher"

---@type table<LogTypes, boolean>
local types = {}

---@type string
local file_path

local M = {}

--- Write to log file
---@param typ string as per log.types config
---@param fmt string for string.format
---@param ... any arguments for string.format
function M.raw(typ, fmt, ...)
  if not M.enabled(typ) then
    return
  end

  local line = string.format(fmt, ...)
  local file = io.open(file_path, "a")
  if file then
    io.output(file)
    io.write(line)
    io.close(file)
  end
end

--- Write to a new file
---@param typ LogTypes as per log.types config
---@param path string absolute path
---@param fmt string for string.format
---@param ... any arguments for string.format
function M.file(typ, path, fmt, ...)
  if not M.enabled(typ) then
    return
  end

  local line = string.format(fmt, ...)
  local file = io.open(path, "w")
  if file then
    io.output(file)
    io.write(line)
    io.close(file)
  end
end

---@class Profile
---@field start number nanos
---@field tag string

--- Write profile start to log file
--- START is prefixed
---@param fmt string for string.format
---@param ... any arguments for string.format
---@return Profile to pass to profile_end
function M.profile_start(fmt, ...)
  local profile = {}
  if M.enabled("profile") then
    profile.start = vim.loop.hrtime()
    profile.tag = string.format((fmt or "???"), ...)
    M.line("profile", "START %s", profile.tag)
  end
  return profile
end

--- Write profile end to log file
--- END is prefixed and duration in seconds is suffixed
---@param profile Profile returned from profile_start
function M.profile_end(profile)
  if M.enabled("profile") and type(profile) == "table" then
    local millis = profile.start and math.modf((vim.loop.hrtime() - profile.start) / 1000000) or -1
    M.line("profile", "END   %s %dms", profile.tag or "", millis)
  end
end

--- Write to log file
--- time and typ are prefixed and a trailing newline is added
---@param typ LogTypes as per log.types config
---@param fmt string for string.format
---@param ... any arguments for string.format
function M.line(typ, fmt, ...)
  if M.enabled(typ) then
    M.raw(typ, string.format("[%s] [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), typ, (fmt or "???")), ...)
  end
end

local inspect_opts = {}

---@param opts table
function M.set_inspect_opts(opts)
  inspect_opts = opts
end

--- Write to log file the inspection of a node
---@param typ LogTypes as per log.types config
---@param node Node node to be inspected
---@param fmt string for string.format
---@param ... any arguments for string.format
function M.node(typ, node, fmt, ...)
  if M.enabled(typ) then
    M.raw(typ, string.format("[%s] [%s] %s\n%s\n", os.date("%Y-%m-%d %H:%M:%S"), typ, (fmt or "???"), vim.inspect(node, inspect_opts)), ...)
  end
end

--- Logging is enabled for typ or all
---@param typ LogTypes as per log.types config
---@return boolean
function M.enabled(typ)
  return file_path ~= nil and (types[typ] or types.all)
end

function M.setup(opts)
  if opts.log and opts.log.enable and opts.log.types then
    types = opts.log.types
    file_path = string.format("%s/nvim-tree.log", vim.fn.stdpath("log"), os.date("%H:%M:%S"), vim.env.USER)
    if opts.log.truncate then
      os.remove(file_path)
    end
    require("nvim-tree.notify").debug("nvim-tree.lua logging to " .. file_path)
  end
end

return M
