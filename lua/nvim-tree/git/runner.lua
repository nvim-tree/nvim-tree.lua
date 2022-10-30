local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"

local Runner = {}
Runner.__index = Runner

function Runner:_parse_status_output(line)
  local status = line:sub(1, 2)
  -- removing `"` when git is returning special file status containing spaces
  local path = line:sub(4, -2):gsub('^"', ""):gsub('"$', "")
  -- replacing slashes if on windows
  if vim.fn.has "win32" == 1 then
    path = path:gsub("/", "\\")
  end
  if #status > 0 and #path > 0 then
    self.output[utils.path_remove_trailing(utils.path_join { self.project_root, path })] = status
  end
  return #line
end

function Runner:_handle_incoming_data(prev_output, incoming)
  if incoming and utils.str_find(incoming, "\n") then
    local prev = prev_output .. incoming
    local i = 1
    for line in prev:gmatch "[^\n]*\n" do
      i = i + self:_parse_status_output(line)
    end

    return prev:sub(i, -1)
  end

  if incoming then
    return prev_output .. incoming
  end

  for line in prev_output:gmatch "[^\n]*\n" do
    self._parse_status_output(line)
  end

  return nil
end

function Runner:_getopts(stdout_handle, stderr_handle)
  local untracked = self.list_untracked and "-u" or nil
  local ignored = (self.list_untracked and self.list_ignored) and "--ignored=matching" or "--ignored=no"
  return {
    args = { "--no-optional-locks", "status", "--porcelain=v1", ignored, untracked, self.path },
    cwd = self.project_root,
    stdio = { nil, stdout_handle, stderr_handle },
  }
end

function Runner:_log_raw_output(output)
  if output and type(output) == "string" then
    log.raw("git", "%s", output)
    log.line("git", "done")
  end
end

function Runner:_run_git_job()
  local handle, pid
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local timer = vim.loop.new_timer()

  local function on_finish(rc)
    self.rc = rc or 0
    if timer:is_closing() or stdout:is_closing() or stderr:is_closing() or (handle and handle:is_closing()) then
      return
    end
    timer:stop()
    timer:close()
    stdout:read_stop()
    stderr:read_stop()
    stdout:close()
    stderr:close()
    if handle then
      handle:close()
    end

    pcall(vim.loop.kill, pid)
  end

  local opts = self:_getopts(stdout, stderr)
  log.line("git", "running job with timeout %dms", self.timeout)
  log.line("git", "git %s", table.concat(utils.array_remove_nils(opts.args), " "))

  handle, pid = vim.loop.spawn(
    "git",
    opts,
    vim.schedule_wrap(function(rc)
      on_finish(rc)
    end)
  )

  timer:start(
    self.timeout,
    0,
    vim.schedule_wrap(function()
      on_finish(-1)
    end)
  )

  local output_leftover = ""
  local function manage_stdout(err, data)
    if err then
      return
    end
    self:_log_raw_output(data)
    output_leftover = self:_handle_incoming_data(output_leftover, data)
  end

  local function manage_stderr(_, data)
    self:_log_raw_output(data)
  end

  vim.loop.read_start(stdout, vim.schedule_wrap(manage_stdout))
  vim.loop.read_start(stderr, vim.schedule_wrap(manage_stderr))
end

function Runner:_wait()
  local function is_done()
    return self.rc ~= nil
  end
  while not vim.wait(30, is_done) do
  end
end

-- This module runs a git process, which will be killed if it takes more than timeout which defaults to 400ms
function Runner.run(opts)
  local ps = log.profile_start("git job %s %s", opts.project_root, opts.path)

  local self = setmetatable({
    project_root = opts.project_root,
    path = opts.path,
    list_untracked = opts.list_untracked,
    list_ignored = opts.list_ignored,
    timeout = opts.timeout or 400,
    output = {},
    rc = nil, -- -1 indicates timeout
  }, Runner)

  self:_run_git_job()
  self:_wait()

  log.profile_end(ps, "git job %s %s", opts.project_root, opts.path)

  if self.rc == -1 then
    log.line("git", "job timed out  %s %s", opts.project_root, opts.path)
  elseif self.rc ~= 0 then
    log.line("git", "job fail rc %d %s %s", self.rc, opts.project_root, opts.path)
  else
    log.line("git", "job success    %s %s", opts.project_root, opts.path)
  end

  return self.output
end

return Runner
