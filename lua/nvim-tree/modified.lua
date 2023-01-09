local M = {}

---@type table<string, boolean> record of which file is modified
M._record = {}

---refresh M.record
function M.reload()
  M._record = {}
  local bufs = vim.fn.getbufinfo { bufmodified = true, buflisted = true }
  for _, buf in pairs(bufs) do
    local path = buf.name
    if path ~= "" then -- not a [No Name] buffer
      -- mark all the parent as modified as well
      while
        M._record[path] ~= true
        -- no need to keep going if already recorded
        -- This also prevents an infinite loop
      do
        M._record[path] = true
        path = vim.fn.fnamemodify(path, ":h")
      end
    end
  end
end

---@param node table
---@return boolean
function M.is_modified(node)
  return M.config.enable
    and M._record[node.absolute_path]
    and (not node.nodes or M.config.show_on_dirs)
    and (not node.open or M.config.show_on_open_dirs)
end

---@param opts table
function M.setup(opts)
  M.config = opts.modified
end

return M
