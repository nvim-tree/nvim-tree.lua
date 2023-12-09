local notify = require "nvim-tree.notify"
local utils = require "nvim-tree.utils"

local M = {}

---@param node Node
function M.fn(node)
  if #M.config.system_open.cmd == 0 then
    require("nvim-tree.utils").notify.warn "Cannot open file with system application. Unrecognized platform."
    return
  end

  local process = {
    cmd = M.config.system_open.cmd,
    args = M.config.system_open.args,
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

function M.setup(opts)
  M.config = {}
  M.config.system_open = opts.system_open or {}

  if #M.config.system_open.cmd == 0 then
    if utils.is_windows then
      M.config.system_open = {
        cmd = "cmd",
        args = { "/c", "start", '""' },
      }
    elseif utils.is_macos then
      M.config.system_open.cmd = "open"
    elseif utils.is_unix then
      M.config.system_open.cmd = "xdg-open"
    end
  end
end

return M
