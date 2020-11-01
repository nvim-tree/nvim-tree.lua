local utils = require'nvim-tree.utils'
local uv = vim.loop
local M = {}

local watchers = {}
local batch_files = {}
local batch_timer = nil

local function batch_events(explorer, fname)
  if batch_timer ~= nil then
    batch_timer:stop()
    batch_timer:close()
    batch_timer = nil
  end

  batch_files[fname] = fname
  batch_timer = uv.new_timer()
  batch_timer:start(150, 0, function()
    batch_timer:stop()
    batch_timer:close()
    batch_timer = nil
    vim.schedule(explorer:refresh(vim.tbl_values(batch_files)))
    batch_files = {}
  end)
end

function M.run(explorer, cwd)
  if watchers[cwd] then return end

  watchers[cwd] = uv.new_fs_event()
  uv.fs_event_start(
    watchers[cwd],
    cwd,
    -- recursive not yet available on linux...
    -- that sucks, so we have to bind for every dir we explore
    { recursive = false },
    function(_, fname) batch_events(explorer, utils.path_join(cwd, fname)) end
  )
end

return M
