local uv = vim.loop
local utils = require'nvim-tree.utils'

local Runner = {}
Runner.__index = Runner

function Runner:_parse_status_output(line)
  local status = line:sub(1, 2)
  -- removing `"` when git is returning special file status containing spaces
  local path = line:sub(4, -2):gsub('^"', ''):gsub('"$', '')
  if #status > 0 and #path > 0 then
    self.output[utils.path_remove_trailing(utils.path_join({self.project_root,path}))] = status
  end
  return #line
end

function Runner:_handle_incoming_data(prev_output, incoming)
  if incoming and utils.str_find(incoming, '\n') then
    local prev = prev_output..incoming
    local i = 1
    for line in prev:gmatch('[^\n]*\n') do
      i = i + self:_parse_status_output(line)
    end

    return prev:sub(i, -1)
  end

  if incoming then
    return prev_output..incoming
  end

  for line in prev_output:gmatch('[^\n]*\n') do
    self._parse_status_output(line)
  end

  return nil
end

function Runner:_getopts(stdout_handle)
  local untracked = self.list_untracked and '-u' or nil
  local ignored = self.list_ignored and '--ignored=matching' or '--ignored=no'
  return {
    args = {"--no-optional-locks", "status", "--porcelain=v1", ignored, untracked},
    cwd = self.project_root,
    stdio = { nil, stdout_handle, nil },
  }
end

function Runner:_run_git_job()
  local handle, pid
  local stdout = uv.new_pipe(false)
  local timer = uv.new_timer()

  local function on_finish(output)
    if timer:is_closing() or stdout:is_closing() or (handle and handle:is_closing()) then
      return
    end
    timer:stop()
    timer:close()
    stdout:read_stop()
    stdout:close()
    if handle then
      handle:close()
    end

    pcall(uv.kill, pid)

    self.on_end(output or self.output)
  end

  handle, pid = uv.spawn(
    "git",
    self:_getopts(stdout),
    vim.schedule_wrap(function() on_finish() end)
  )

  timer:start(self.timeout, 0, vim.schedule_wrap(function() on_finish({}) end))

  local output_leftover = ''
  local function manage_output(err, data)
    if err then return end
    output_leftover = self:_handle_incoming_data(output_leftover, data)
  end

  uv.read_start(stdout, vim.schedule_wrap(manage_output))
end

-- This module runs a git process, which will be killed if it takes more than timeout which defaults to 400ms
function Runner.run(opts)
  local self = setmetatable({
    project_root = opts.project_root,
    list_untracked = opts.list_untracked,
    list_ignored = opts.list_ignored,
    timeout = opts.timeout or 400,
    output = {},
    on_end = opts.on_end,
  }, Runner)

  self:_run_git_job()
end

return Runner
