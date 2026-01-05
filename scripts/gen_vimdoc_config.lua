---@diagnostic disable: undefined-doc-name

--- @type table<string,nvim.gen_vimdoc.Config>
local config = {
  decorator = {
    filename = "nvim-tree-lua.txt",
    -- filename = "decorator.txt",
    section_order = {
      "config.lua",
      "api_decorator.lua",
    },
    files = {
      -- module is derived soley from the file name, first letter capitalised
      "lua/nvim-tree/_meta/api_decorator.lua",
      "lua/nvim-tree/_meta/config.lua",
    },
    section_fmt = function(name)
      if name == "Config" then
        return "Lua module: nvim_tree.Config"
      elseif name == "Api_decorator" then
        return "Lua module: nvim_tree.api.decorator"
      end
      error(string.format("unknown module %s passed to section_fmt", name))
    end,
    helptag_fmt = function(name)
      -- used to locate the first section only, others will be rendered after
      if name == "Config" then
        return "nvim-tree-config"
      elseif name == "Api_decorator" then
        return "nvim-tree-api-decorator"
      end
      error(string.format("unknown module %s passed to helptag_fmt", name))
    end,
    fn_helptag_fmt = function(fun)
      -- Modified copy of fn_helptag_fmt_common
      -- Uses fully qualified class name in the tag for methods.
      -- The module is used everywhere else, however not available for classes.
      local fn_sfx = fun.table and "" or "()"
      if fun.classvar then
        return string.format("%s:%s%s", fun.class or fun.classvar, fun.name, fn_sfx)
      end
      if fun.module then
        return string.format("%s.%s%s", fun.module, fun.name, fn_sfx)
      end
      return fun.name .. fn_sfx
    end,
  }
}

return config
