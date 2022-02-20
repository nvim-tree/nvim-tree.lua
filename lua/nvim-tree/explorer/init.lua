local uv = vim.loop

local git = require"nvim-tree.git"
local renderer = require"nvim-tree.renderer"

local M = {}

M.explore = require"nvim-tree.explorer.explore".explore
M.reload = require"nvim-tree.explorer.reload".reload

local Explorer = {}
Explorer.__index = Explorer

function Explorer.new(cwd)
  cwd = uv.fs_realpath(cwd or uv.cwd())
  return setmetatable({
    cwd = cwd,
    nodes = {}
  }, Explorer)
end

function Explorer:_load(node)
  local cwd = node.cwd or node.link_to or node.absolute_path
  git.load_project_status(cwd, function(git_statuses)
    M.explore(node, git_statuses)
    if type(self.init_cb) == "function" then
      self.init_cb(self)
      self.init_cb = nil
    end
  end)
end

function Explorer:expand(node)
  self.init_cb = renderer.draw
  self:_load(node)
end

function Explorer:init(f)
  self.init_cb = f
  self:_load(self)
end

function M.setup(opts)
  require"nvim-tree.explorer.utils".setup(opts)
end

M.Explorer = Explorer

return M
