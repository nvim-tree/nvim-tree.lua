local _, sqlite = pcall(require, 'sqlite')

local uv = vim.loop
local utils = require'nvim-tree.utils'

local Db = {}
Db.__index = Db

local function rand()
  return tostring(math.floor(math.random() * 100 % 20))
end

local function create_uri()
  local cache = vim.fn.stdpath "cache"
  local path = utils.path_join({cache, "nvim-tree-sqlite-"..rand()})
  while uv.fs_access(path, 'R') do
    path = utils.path_join({cache, "nvim-tree-sqlite-"..rand()})
  end
  return path
end

local function init_db()
  local uri = create_uri()
  local db = sqlite {
    uri = uri,
    statuses = {
      path = "text",
      status = "text",
    },
  }
  db:open()
  vim.cmd [[
    augroup NvimTreeSqlite
      au VimLeavePre * lua require'nvim-tree.git'.cleanup()
    augroup END
  ]]
  return db, uri
end

function Db.new()
  local db, uri = init_db()
  return setmetatable({
    db = db,
    uri = uri,
    insertion_cache = {}
  }, Db)
end

function Db:cleanup()
  if self.db:isopen() then
    self.db:close()
  end
  pcall(uv.fs_unlink, self.uri)
end

function Db:insert_cache()
  if #self.insertion_cache == 0 then
    return
  end
  self.db:insert("statuses", self.insertion_cache)
  self.insertion_cache = {}
end

function Db:clear()
  self.db:eval("DELETE FROM statuses")
end

function Db:insert(path, status)
  if #self.insertion_cache < 2000 then
    return table.insert(self.insertion_cache, { path = path, status = status })
  else
    self:insert_cache()
  end
end

function Db:list_statuses_under_uri(cwd)
  local query = "select * from statuses where path LIKE ?"
  local statuses = self.db:eval(query, cwd..'%')
  if type(statuses) == "table" then
    return statuses
  else
    return {}
  end
end

function Db:clean_paths(cwd)
  self.db:eval("delete from statuses where path LIKE ?", cwd..'%')
end

return Db
