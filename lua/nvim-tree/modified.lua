local M = {}

---@type table<string, boolean> record of which file is modified
M.record = {}

---refresh M.record
function M.reload()
  M.record = {}
  local bufs = vim.fn.getbufinfo { bufmodified = true, buflisted = true }
  for _, buf in pairs(bufs) do
    local path = buf.name
    M.record[path] = true
    while path ~= vim.fn.getcwd() and path ~= "/" do
      path = vim.fn.fnamemodify(path, ":h")
      M.record[path] = true
    end
  end
end

---@param node table TODO: we should probably have a Node type
---@return boolean
function M.is_modified(node)
  return M.config.enable
    and M.record[node.absolute_path]
    and (not node.nodes or M.config.show_on_dirs)
    and (not node.open or M.config.show_on_open_dirs)
end

---@param opts table
function M.setup(opts)
  M.config = opts.modified
end

return M
