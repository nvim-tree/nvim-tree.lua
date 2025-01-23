-- Copyright 2019 Yazdani Kiyan under MIT License
local notify = require("nvim-tree.notify")

local M = {}

---@param node Node
---@param opts ApiNodeDeleteWipeBufferOpts|nil
---@return nil
function M.delete(node, opts)
  M.delete_buffer("delete", node.absolute_path, opts)
end

---@param node Node
---@param opts ApiNodeDeleteWipeBufferOpts|nil
---@return nil
function M.wipe(node, opts)
  M.delete_buffer("wipe", node.absolute_path, opts)
end

---@alias ApiNodeDeleteWipeBufferMode '"delete"'|'"wipe"'

---@param mode ApiNodeDeleteWipeBufferMode
---@param filename string
---@param opts ApiNodeDeleteWipeBufferOpts|nil
---@return nil
function M.delete_buffer(mode, filename, opts)
  if type(mode) ~= "string" then
    mode = "delete"
  end

  local buf_fn = vim.cmd.bdelete
  if mode == "wipe" then
    buf_fn = vim.cmd.bwipe
  end

  opts = opts or { force = false }

  local notify_node = notify.render_path(filename)

  -- check if buffer for file at cursor exists and if it is loaded
  local bufnr_at_filename = vim.fn.bufnr(filename)
  if bufnr_at_filename == -1 or vim.fn.getbufinfo(bufnr_at_filename)[1].loaded == 0 then
    notify.info("No loaded buffer coincides with " .. notify_node)
    return
  end

  local force = opts.force
  -- check if buffer is modified
  local buf_modified = vim.fn.getbufinfo(bufnr_at_filename)[1].changed
  if not force and buf_modified == 1 then
    notify.error("Buffer for file " .. notify_node .. " is modified")
    return
  end

  buf_fn({ filename, bang = force })
end

return M
