local utils = require("nvim-tree.utils")

local DecoratorBookmarks = require("nvim-tree.renderer.decorator.bookmarks")
local DecoratorCopied = require("nvim-tree.renderer.decorator.copied")
local DecoratorCut = require("nvim-tree.renderer.decorator.cut")
local DecoratorDiagnostics = require("nvim-tree.renderer.decorator.diagnostics")
local DecoratorGit = require("nvim-tree.renderer.decorator.git")
local DecoratorModified = require("nvim-tree.renderer.decorator.modified")
local DecoratorHidden = require("nvim-tree.renderer.decorator.hidden")
local DecoratorOpened = require("nvim-tree.renderer.decorator.opened")
local DecoratorUser = require("nvim-tree.renderer.decorator.user")

local M = {
  -- Globally registered decorators including user. Lowest priority first.
  ---@type Decorator[]
  registered = {
    DecoratorGit,
    DecoratorOpened,
    DecoratorHidden,
    DecoratorModified,
    DecoratorBookmarks,
    DecoratorDiagnostics,
    DecoratorCopied,
    DecoratorCut,
  }
}

---@param opts RegisterOpts
function M.register(opts)
  if not opts or not opts.decorator then
    return
  end

  if vim.tbl_contains(M.registered, opts.decorator) then
    return
  end

  for i, d in ipairs(M.registered) do
    if d:is(DecoratorUser) and d == opts.below or d.name == opts.below then
      table.insert(M.registered, i, opts.decorator)
      return
    end
  end

  -- default to highest at the top
  table.insert(M.registered, opts.decorator)
end

---@param opts UnRegisterOpts
function M.unregister(opts)
  if not opts or not opts.decorator then
    return
  end

  utils.array_remove(M.registered, opts.decorator)
end

return M
