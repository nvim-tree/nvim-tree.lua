local uv = vim.loop

local git = require"nvim-tree.git"

local M = {}

M.explore = require"nvim-tree.explorer.explore".explore
M.reload = require"nvim-tree.explorer.reload".reload

local Explorer = {}
Explorer.__index = Explorer

function Explorer.new(cwd)
  cwd = cwd or uv.cwd()
  return setmetatable({
    cwd = cwd,
    nodes = {}
  }, Explorer)
end

function Explorer:_load(cwd, node)
  git.load_project_status(cwd, function(git_statuses)
    M.explore(node, cwd, git_statuses)
    if type(self.init_cb) == "function" then
      self.init_cb(self)
      self.init_cb = nil
    end
  end)
end

function Explorer:expand(node)
  self.init_cb = require"nvim-tree.lib".redraw
  self:_load(node.link_to or node.absolute_path, node)
end

function Explorer:init(f)
  self.init_cb = f
  self:_load(self.cwd, self)
end

function M.setup(opts)
  require"nvim-tree.explorer.utils".setup(opts)
end

M.Explorer = Explorer

return M
