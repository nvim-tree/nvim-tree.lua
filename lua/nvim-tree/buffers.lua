local DirectoryNode = require("nvim-tree.node.directory")

local M = {}

---@type table<string, boolean> record of which file is modified
M._modified = {}

---refresh M._modified
function M.reload_modified()
  M._modified = {}
  local bufs = vim.fn.getbufinfo({ bufmodified = 1, buflisted = 1 })
  for _, buf in pairs(bufs) do
    local path = buf.name
    if path ~= "" then -- not a [No Name] buffer
      -- mark all the parent as modified as well
      while M._modified[path] ~= true do
        -- no need to keep going if already recorded
        -- This also prevents an infinite loop
        M._modified[path] = true
        path = vim.fn.fnamemodify(path, ":h")
      end
    end
  end
end

---@param node Node
---@return boolean
function M.is_modified(node)
  if not M.config.modified.enable then
    return false
  end

  if not M._modified[node.absolute_path] then
    return false
  end

  local dir = node:as(DirectoryNode)
  if dir then
    if not M.config.modified.show_on_dirs then
      return false
    end

    if dir.open and not M.config.modified.show_on_open_dirs then
      return false
    end
  end

  return true
end

---A buffer exists for the node's absolute path
---@param node Node
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
