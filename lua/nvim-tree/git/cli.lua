local notify = require "nvim-tree.notify"
local log = require "nvim-tree.log"

local M = {}

--- See h `uv.spawn-options` for full list of props
--- @class vim.uv.SpawnOptions
--- @field args string[] args to be passed to git command e.g. -C
--- @field env table|nil
--- @field cwd table|nil
--- @field detached boolean|nil detach process from parent
--- @field timeout number|nil timeout before hanged git process gets killed

--- A very lightweight generic git cli command wrapper powered by libuv;
--- it's probably worth to consider to import another library
--- @param uv_spawn_opts vim.uv.SpawnOptions uv.spaw like options
--- @param on_err_or_data fun(err: string|nil, data: string|nil) error handler callback
--- @param on_exit? fun(code: number, signal: number) error handler callback
--- @param on_timeout? fun(): nil called if process timedout
function M.cli(uv_spawn_opts, on_err_or_data, on_exit, on_timeout)
  local process
  local process_exited = false
  local stdin = vim.loop.new_pipe()
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()

  uv_spawn_opts = vim.tbl_extend("keep", uv_spawn_opts, {
    stdio = { stdin, stdout, stderr },
  })

  local stream_context = { failed = false }
  local on_data = function(err, data)
    local failed = stream_context.failed or false
    if err then
      if not failed then
        stream_context.failed = err
        on_err_or_data(err, data)
      end
      ---@diagnostic disable-next-line: ambiguity-1
      notify.error("git" .. table.concat(uv_spawn_opts.args) .. " job has failed: " .. err or "")
    else
      on_err_or_data(nil, data)
    end
  end

  -- default exit handler; just reporting
  ---@diagnostic disable-next-line: redefined-local
  local _on_exit = function(process_exit_code, signal)
    process_exited = true
    if process_exit_code ~= 0 then
      log.line("git", "git " .. table.concat(uv_spawn_opts.args) .. " job has failed with %s exit code", process_exit_code)
    end
    -- Free FIFOs: uv library requires for handles to be closed upon exit
    -- Ref: https://docs.libuv.org/en/v1.x/guide/processes.html#spawning-child-processes
    stdin:shutdown(function()
      process:close()
    end)
    stdout:shutdown()
    stderr:shutdown()

    if on_exit then
      on_exit(process_exit_code, signal)
    end
  end

  process = vim.loop.spawn("git", uv_spawn_opts, _on_exit)
  vim.loop.read_start(stdout, vim.schedule_wrap(on_data))
  vim.loop.read_start(stderr, vim.schedule_wrap(on_data))

  -- If git command takes too long to run, kill the process
  -- the option .timeout have to be explicitly set to activate this featureg;
  vim.defer_fn(function()
    if process_exited or stream_context.failed or (process and process:is_closing()) then
      return
    end
    local kill_exit_code = process:kill()
    if kill_exit_code == 0 then
      if on_timeout then
        on_timeout()
      end
    end
  end, uv_spawn_opts.timeout)
end

-- note: keep this in sync with M.cli
M.git = M.cli

return M
