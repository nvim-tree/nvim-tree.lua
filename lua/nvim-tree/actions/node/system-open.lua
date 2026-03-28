local notify = require("nvim-tree.notify")
local config = require("nvim-tree.config")

local M = {}

---@param node Node
local function user(node)
  local cmd = config.g.system_open.cmd
  local args = config.g.system_open.args

  if #cmd == 0 then
    if config.os.windows then
      cmd = "cmd"
      args = { "/c", "start", '""' }
    elseif config.os.macos then
      cmd = "open"
    elseif config.os.unix then
      cmd = "xdg-open"
    end
  end

  if #cmd == 0 then
    notify.warn("Cannot open file with system application. Unrecognized platform.")
    return
  end

  local process = {
    cmd = cmd,
    args = args,
    errors = "\n",
    stderr = vim.loop.new_pipe(false),
  }
  table.insert(process.args, node.link_to or node.absolute_path)

  local opts = {
    args = process.args,
    stdio = { nil, nil, process.stderr },
    detached = true,
  }

  process.handle, process.pid = vim.loop.spawn(process.cmd, opts, function(code)
    process.stderr:read_stop()
    process.stderr:close()
    process.handle:close()
    if code ~= 0 then
      notify.warn(string.format("system_open failed with return code %d: %s", code, process.errors))
    end
  end)

  table.remove(process.args)
  if not process.handle then
    notify.warn(string.format("system_open failed to spawn command '%s': %s", process.cmd, process.pid))
    return
  end
  vim.loop.read_start(process.stderr, function(err, data)
    if err then
      return
    end
    if data then
      process.errors = process.errors .. data
    end
  end)
  vim.loop.unref(process.handle)
end

---@param node Node
local function native(node)
  local _, err = vim.ui.open(node.link_to or node.absolute_path)

  -- err only provided on opener executable not found hence logging path is not useful
  if err then
    notify.warn(err)
  end
end

---@param node Node
function M.fn(node)
  -- TODO #2430 always use native once 0.10 is the minimum neovim version
  if vim.fn.has("nvim-0.19") == 1 and #config.g.system_open.cmd == 0 then
    native(node)
  else
    user(node)
  end
end

return M
