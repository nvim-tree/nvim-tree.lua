local M = {}

---@type table<string, boolean> record of which file is modified
M._modified = {}

---@type number unloaded_bufnr for the duration of BufUnload
M._unloaded_bufnr = nil

---refresh M._modified
function M.reload_modified()
  M._modified = {}
  local bufs = vim.fn.getbufinfo { bufmodified = true, buflisted = true }
  for _, buf in pairs(bufs) do
    local path = buf.name
    if path ~= "" then -- not a [No Name] buffer
      -- mark all the parent as modified as well
      while
        M._modified[path] ~= true
        -- no need to keep going if already recorded
        -- This also prevents an infinite loop
      do
        M._modified[path] = true
        path = vim.fn.fnamemodify(path, ":h")
      end
    end
  end
end

---@param node table
---@return boolean
function M.is_modified(node)
  return node
    and M.config.modified.enable
    and M._modified[node.absolute_path]
    and (not node.nodes or M.config.modified.show_on_dirs)
    and (not node.open or M.config.modified.show_on_open_dirs)
end

---A buffer exists for the node's absolute path and it's not in the middle of a BufUnload handler.
---@param node table
---@return boolean
function M.is_opened(node)
  return node and vim.fn.bufloaded(node.absolute_path) > 0 and vim.fn.bufnr(node.absolute_path) ~= M._unloaded_bufnr
end

---Set the unloaded bufnr - at the start of the BufUnload handler.
---@param bufnr number
function M.set_unloaded_bufnr(bufnr)
  M._unloaded_bufnr = bufnr
end

---Reset the unloaded bufnr - at the end of the BufUnload handler.
function M.reset_unloaded_bufnr()
  M._unloaded_bufnr = nil
end

---@param opts table
function M.setup(opts)
  M.config = {
    modified = opts.modified,
  }
end

return M
