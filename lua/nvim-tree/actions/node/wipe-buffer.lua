-- Copyright 2019 Yazdani Kiyan under MIT License
local notify = require("nvim-tree.notify")

local M = {}

---@param filename string
---@param opts ApiNodeDeleteBufferOpts|nil
---@return nil
function M.fn(filename, opts)
  opts = opts or { force = false }

  local notify_node = notify.render_path(filename)

  -- check if buffer for file at cursor exists and if it is loaded
  local bufnr_at_filename = vim.fn.bufnr(filename)
  if bufnr_at_filename == -1 or vim.fn.getbufinfo(bufnr_at_filename)[1].loaded == 0 then
    notify.error("No loaded buffer coincides with " .. notify_node)
    return
  end

  local force = opts.force
  -- check if buffer is modified
  local buf_modified = vim.fn.getbufinfo(bufnr_at_filename)[1].changed
  if not force and buf_modified == 1 then
    notify.error("Buffer for file " .. notify_node .. " is modified")
    return
  end

  vim.cmd.bwipe({ filename, bang = force })
end

function M.setup(opts)
end

return M
