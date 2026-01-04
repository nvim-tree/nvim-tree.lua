---@diagnostic disable: undefined-doc-name

--- @param fun nvim.luacats.parser.fun
--- @return string
local function fn_helptag_fmt_common0(fun)
  local fn_sfx = fun.table and '' or '()'
  if fun.classvar then
    return string.format('%s:%s%s', fun.classvar, fun.name, fn_sfx)
  end
  if fun.module then
    return string.format('%s.%s%s', fun.module, fun.name, fn_sfx)
  end
  return fun.name .. fn_sfx
end

return {
  filename = "decorator.txt",
  section_order = {
    "api_decorator.lua",
  },
  files = {
    -- module is derived soley from the file name, first letter capitalised
    -- 'runtime/lua/nvim-tree/foo/api_decorator.lua',
    "/home/alex/src/nvim-tree/master/lua/nvim-tree/_meta/api_decorator.lua"
  },
  section_fmt = function(name)
    if name == "Api_decorator" then
      return "Lua module: nvim_tree.api.decorator"
    end
    error(string.format("unknown module %s passed to section_fmt", name))
  end,
  helptag_fmt = function(name)
    -- used to locate the help section
    if name == "Api_decorator" then
      return "nvim-tree-decorators"
    end
    error(string.format("unknown module %s passed to helptag_fmt", name))
  end,
  fn_helptag_fmt = function(fun)
    -- use the fully qualified class name in the tag for methods
    -- this is done everywhere but for classes
    local common = fn_helptag_fmt_common0(fun)
    local helptag = common
    if fun.class then
      helptag = common:gsub(fun.classvar, fun.class)
    end
    return helptag
  end,
}
