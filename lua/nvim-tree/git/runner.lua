local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")
local notify = require("nvim-tree.notify")

local Class = require("nvim-tree.classic")

---@class (exact) GitRunner: nvim_tree.Class
---@field private toplevel string absolute path
---@field private path string? absolute path
---@field private list_untracked boolean
---@field private list_ignored boolean
---@field private timeout integer
---@field private callback fun(path_xy: nvim_tree.git.PathXY)?
---@field private path_xy nvim_tree.git.PathXY
---@field private rc integer? -- -1 indicates timeout
local GitRunner = Class:extend()

---@class GitRunner
---@overload fun(args: GitRunnerArgs): GitRunner

---@class (exact) GitRunnerArgs
---@field toplevel string absolute path
---@field path string? absolute path
---@field list_untracked boolean
---@field list_ignored boolean
---@field timeout integer
---@field callback fun(path_xy: nvim_tree.git.PathXY)?

local timeouts = 0
local MAX_TIMEOUTS = 5

---@protected
---@param args GitRunnerArgs
function GitRunner:new(args)
  self.toplevel       = args.toplevel
  self.path           = args.path
  self.list_untracked = args.list_untracked
  self.list_ignored   = args.list_ignored
  self.timeout        = args.timeout
  self.callback       = args.callback

  self.path_xy        = {}
  self.rc             = nil
end

---@private
---@param status string
---@param path string|nil
function GitRunner:parse_status_output(status, path)
  if not path then
    return
  end

  -- replacing slashes if on windows
  if vim.fn.has("win32") == 1 then
    path = path:gsub("/", "\\")
  end
  if #status > 0 and #path > 0 then
    self.path_xy[utils.path_remove_trailing(utils.path_join({ self.toplevel, path }))] = status
  end
end

---@private
---@param prev_output string
---@param incoming string
---@return string
function GitRunner:handle_incoming_data(prev_output, incoming)
  if incoming and utils.str_find(incoming, "\n") then
    local prev = prev_output .. incoming
    local i = 1
    local skip_next_line = false
    for line in prev:gmatch("[^\n]*\n") do
      if skip_next_line then
        skip_next_line = false
      else
        local status = line:sub(1, 2)
        local path = line:sub(4, -2)
        if utils.str_find(status, "R") then
          -- skip next line if it is a rename entry
          skip_next_line = true
        end
        self:parse_status_output(status, path)
      end
      i = i + #line
    end

    return prev:sub(i, -1)
  end

  if incoming then
    return prev_output .. incoming
  end

  for line in prev_output:gmatch("[^\n]*\n") do
    self:parse_status_output(line)
  end

  return ""
end

---@private
---@param stdout_handle uv.uv_pipe_t
---@param stderr_handle uv.uv_pipe_t
---@return uv.spawn.options
function GitRunner:get_spawn_options(stdout_handle, stderr_handle)
  local untracked = self.list_untracked and "-u" or nil
  local ignored = (self.list_untracked and self.list_ignored) and "--ignored=matching" or "--ignored=no"
  return {
    args  = { "--no-optional-locks", "status", "--porcelain=v1", "-z", ignored, untracked, self.path },
    cwd   = self.toplevel,
    stdio = { nil, stdout_handle, stderr_handle },
  }
end

---@private
---@param output string
function GitRunner:log_raw_output(output)
  if log.enabled("git") and output and type(output) == "string" then
    log.raw("git", "%s", output)
    log.line("git", "done")
  end
end

---@private
---@param callback function|nil
function GitRunner:run_git_job(callback)
  local handle, pid
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local timer = vim.loop.new_timer()

  if stdout == nil or stderr == nil or timer == nil then
    return
  end

  local function on_finish(rc)
    self.rc = rc or 0
    if timer:is_closing() or stdout:is_closing() or stderr:is_closing() or (handle and handle:is_closing()) then
      if callback then
        callback()
      end
      return
    end
    timer:stop()
    timer:close()
    stdout:read_stop()
    stderr:read_stop()
    stdout:close()
    stderr:close()

    -- don't close the handle when killing as it will leave a zombie
    if rc == -1 then
      pcall(vim.loop.kill, pid, "sigkill")
    elseif handle then
      handle:close()
    end

    if callback then
      callback()
    end
  end

  local spawn_options = self:get_spawn_options(stdout, stderr)
  log.line("git", "running job with timeout %dms", self.timeout)
  log.line("git", "git %s",                        table.concat(utils.array_remove_nils(spawn_options.args), " "))

  handle, pid = vim.loop.spawn(
    "git",
    spawn_options,
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
    if data then
      data = data:gsub("%z", "\n")
    end
    self:log_raw_output(data)
    output_leftover = self:handle_incoming_data(output_leftover, data)
  end

  local function manage_stderr(_, data)
    self:log_raw_output(data)
  end

  vim.loop.read_start(stdout, vim.schedule_wrap(manage_stdout))
  vim.loop.read_start(stderr, vim.schedule_wrap(manage_stderr))
end

---@private
function GitRunner:wait()
  local function is_done()
    return self.rc ~= nil
  end

  while not vim.wait(30, is_done) do
  end
end

---@private
function GitRunner:finalise()
  if self.rc == -1 then
    log.line("git", "job timed out  %s %s", self.toplevel, self.path)
    timeouts = timeouts + 1
    if timeouts == MAX_TIMEOUTS then
      notify.warn(string.format("%d git jobs have timed out after git.timeout %dms, disabling git integration.", timeouts,
        self.timeout))
      require("nvim-tree.git").disable_git_integration()
    end
  elseif self.rc ~= 0 then
    log.line("git", "job fail rc %d %s %s", self.rc, self.toplevel, self.path)
  else
    log.line("git", "job success    %s %s", self.toplevel, self.path)
  end
end

---Return nil when callback present
---@private
---@return nvim_tree.git.PathXY?
function GitRunner:execute()
  local async = self.callback ~= nil
  local profile = log.profile_start("git %s job %s %s", async and "async" or "sync", self.toplevel, self.path)

  if async and self.callback then
    -- async, always call back
    self:run_git_job(function()
      log.profile_end(profile)

      self:finalise()

      self.callback(self.path_xy)
    end)
  else
    -- sync, maybe call back
    self:run_git_job()
    self:wait()

    log.profile_end(profile)

    self:finalise()

    if self.callback then
      self.callback(self.path_xy)
    else
      return self.path_xy
    end
  end
end

---Static method to run a git process, which will be killed if it takes more than timeout
---Return nil when callback present
---@param args GitRunnerArgs
---@return nvim_tree.git.PathXY?
function GitRunner:run(args)
  local runner = GitRunner(args)

  return runner:execute()
end

return GitRunner
