local M = {}

---@type table<string, boolean> record of which file is modified
M._modified = {}

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

---A buffer exists for the node's absolute path
---@param node table
---@return boolean
function M.is_opened(node)
  return node and vim.fn.bufloaded(node.absolute_path) > 0
end

---@param opts table
function M.setup(opts)
  M.config = {
    modified = opts.modified,
  }
end

return M
