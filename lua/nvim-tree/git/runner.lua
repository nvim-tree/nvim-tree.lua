local uv = vim.loop
local utils = require'nvim-tree.utils'

local Runner = {}
Runner.__index = Runner

local function handle_line_to_db(db, line, base)
  local status = line:sub(1, 2)
  local path = line:sub(4, -2)
  if #status > 0 and #path > 0 then
    db:insert(utils.path_remove_trailing(utils.path_join({base,path})), status)
  end
  return #line
end

-- @param db: sqlite database connection
-- @param _data: {string} leftover data (if any)
-- @param data: {string} incoming data
-- @param cwd: {string} root cwd
-- @returns {string} or {nil}
local function handle_incoming_data(db, p_data, data, cwd)
  if data and vim.fn.stridx(data, '\n') ~= -1 then
    local prev = p_data..data
    local i = 0
    for line in prev:gmatch('[^\n]*\n') do
      i = i + handle_line_to_db(db, line, cwd)
    end

    return prev:sub(i, -1)
  end

  if data then
    return p_data..data
  end

  for line in p_data:gmatch('[^\n]*\n') do
    handle_line_to_db(db, line, cwd)
  end

  return nil
end

-- @private
function Runner:_getopts(stdout_handle)
  local untracked = self.show_untracked and '-u' or nil
  local ignored = self.with_ignored and '--ignored=matching' or '--ignored=no'
  return {
    args = {"status", "--porcelain=v1", ignored, untracked},
    cwd = self.toplevel,
    stdio = { nil, stdout_handle, nil },
  }
end

-- @private
-- We need to parse incoming data incrementally and add it to a database
-- to avoid burning the lua memory, which can happen on very large repositories,
-- mostly when ignored and untracked options are set.
function Runner:_populate_db()
  local handle
  local stdout = uv.new_pipe(false)

  handle = uv.spawn("git", self:_getopts(stdout), vim.schedule_wrap(function()
    self.db:insert_cache()
    self.and_then()
    stdout:read_stop()
    stdout:close()
    handle:close()
  end))

  local _data = ''
  uv.read_start(stdout, vim.schedule_wrap(function(err, data)
    if err then return end
    handle_incoming_data(self.db, _data, data, self.toplevel)
  end))
end

function Runner:run(and_then)
  self.and_then = and_then
  self:_populate_db()
end

function Runner.new(opts)
  opts.db:clean_paths(opts.toplevel)
  return setmetatable({
    db = opts.db,
    toplevel = opts.toplevel,
    show_untracked = opts.show_untracked,
    with_ignored = opts.with_ignored,
  }, Runner)
end

return Runner
