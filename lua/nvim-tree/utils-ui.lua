--- Various utility classes and functions for vim.ui.input

local M = {}

--- Options affect what part of the path_base the :prepare() returns
--- At least one field must be specified
--- @class InputPathEditorOpts
--- @field basename boolean|nil - basename of the path_base e.g. foo  in foo.lua
--- @field absolute boolean|nil - absolute path: the path_base
--- @field filename boolean|nil - filename of the path_base: foo.lua
--- @field dirname boolean|nil - parent dir of the path_base
--- @field relative boolean|nil - cwd relative path
--- @field is_dir boolean|nil - hint whether path_base is a directory

--- @class InputPathEditorInstance
--- @field constructor InputPathEditor
--- @field opts InputPathEditorOpts
--- @field prepare fun(self):string
--- @field restore fun(self, path_modified: string):string

--- Class to modify parts of the path_base and restore it later.
--- path_base is expected to be absolute
--- The :prepare() method returns a piece of original path_base; it's intended to be modified by user via `vim.ui.input({ default = prepared_path })` prompt.
--- The opts determines what part the path_base :prepare() will return.
--- The :restore(path_modified) to restores absolute :path_base with user applied modifications.
--- Usage example (uncomment, put at the end, and run :luafile %):
---   local Input_path_editor = require("nvim-tree.utils.vim-ui").Input_path_editor
---   local INPUT = vim.fn.expand "%:p"
---   local i = Input_path_editor:new(INPUT, { dirname = true })
---   local prompt = i:prepare()
---   print(prompt)
---
---   vim.ui.input({
---     prompt = "Rename path to: ",
---     default = prompt,
---   }, function(default_modified)
---     default_modified = default_modified and i:restore(default_modified) or i:restore(prompt)
---     vim.cmd "normal! :" -- clear prompt
---     local OUTPUT = default_modified
---     print(OUTPUT)
---   end)
--- @class InputPathEditor
--- @field new fun(self: InputPathEditor, path_base: string, opts?: InputPathEditorOpts): InputPathEditorInstance
--- @field prototype InputPathEditorInstance
--- @diagnostic disable-next-line: missing-fields
M.Input_path_editor = { prototype = { constructor = M.Input_path_editor } }
M.Input_path_editor._mt = {
  __index = function(table, key)
    if key == "constructor" then
      return M.Input_path_editor
    end
    return table.constructor.prototype[key] or table.constructor.super and table.constructor.super.prototype[key]
  end,
}
M.Input_path_editor.fnamemodify = vim.fn.fnamemodify
--- Create new vim.ui.input
--- @param path string path to prepare for prompt
function M.Input_path_editor:new(path, opts)
  local instance = {}
  instance.constructor = self
  setmetatable(instance, self._mt)

  local opts_default = { absolute = true }
  if opts then
    -- at least one opt should be set
    local opts_set = false
    --- @diagnostic disable-next-line: unused-local
    -- luacheck: no unused args
    for _, value in pairs(opts) do
      if value then
        opts_set = true
        break
      end
    end
    instance.opts = opts_set and opts or opts_default
  else
    instance.opts = opts_default
  end

  local fnamemodify = self.fnamemodify
  instance.filename = fnamemodify(path, ":t")
  instance.path_is_dir = opts.is_dir or path:sub(-1) == "/"
  instance.path_is_dot = instance.filename:sub(1, 1) == "."

  if instance.path_is_dir then
    path = path:sub(1, #path - 1)
  end

  -- optimizing
  if instance.opts.filename or instance.opts.basename or instance.opts.dirname then
    instance.path_dirname = path:sub(1, #path - #instance.filename)
  end

  if instance.opts.basename then
    -- Handle edgy cases where a .dot folder might have .d postfix (.dot.d)
    local path_ext = fnamemodify(instance.filename, ":e")
    if path_ext == "" then
      instance.path_ext = nil
    else
      instance.path_ext = path_ext
    end
  end

  if instance.opts.relative then
    instance.path_relative = fnamemodify(path, ":.")
    instance.path_relative_dir = path:sub(0, #path - #instance.path_relative)
  end

  instance.path = path
  return instance
end

--- Extract a piece of path to be modified by ui.input()
--- Put return value into ui.input({ default = <return> })
--- @return string path_prepared
function M.Input_path_editor.prototype:prepare()
  local opts = self.opts
  local path = self.path
  local fnamemodify = self.constructor.fnamemodify
  local path_prepared = path

  if opts.absolute then
    path_prepared = path
  elseif opts.filename then
    path_prepared = fnamemodify(path, ":t")
  elseif opts.basename then
    path_prepared = fnamemodify(path, ":t:r")
  elseif opts.dirname then
    path_prepared = self.path_dirname
  elseif opts.relative then
    path_prepared = self.path_relative
  end

  return path_prepared
end

--- Restore prepared path by using path_modified
--- @return string path_modified
function M.Input_path_editor.prototype:restore(path_modified)
  if type(self.opts) ~= "table" then
    error("you have to call :prepare(...) first", 2)
  end

  local opts = self.opts
  local path_restored = self.path
  if opts.absolute then
    path_restored = path_modified
  elseif opts.filename then
    path_restored = self.path_dirname .. path_modified
  elseif opts.basename then
    path_restored = self.path_dirname .. path_modified .. (self.path_ext and "." .. self.path_ext or "")
  elseif opts.dirname then
    path_restored = path_modified
  elseif opts.relative then
    path_restored = self.path_relative_dir .. path_modified
  end

  return path_restored
end

return M
