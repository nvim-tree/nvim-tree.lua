---@diagnostic disable: undefined-doc-name

-- module name is derived as the file name with the first letter capitalised
local modules = {
  Api = {
    order = 2,
    helptag = "nvim-tree-api",
    title = "Lua module: nvim_tree.api",
    path = "lua/nvim-tree/_meta/api.lua",
  },
  Config = {
    order = 1,
    helptag = "nvim-tree-module",
    title = "Lua module: nvim_tree",
    path = "lua/nvim-tree/_meta/config.lua",
  },
  Api_decorator = {
    order = 3,
    helptag = "nvim-tree-api-decorator",
    title = "Lua module: nvim_tree.api.decorator",
    path = "lua/nvim-tree/_meta/api_decorator.lua",
  },
}

--- @type table<string,nvim.gen_vimdoc.Config>
local config = {
  decorator = {
    filename = "nvim-tree-lua.txt",

    -- file name sets order
    section_order = (function()
      local ret = {}
      for _, c in pairs(modules) do
        ret[c.order] = vim.fn.fnamemodify(c.path, ":t")
      end
      return ret
    end)(),

    -- full path, will be ordered by section_order
    files = (function()
      local ret = {}
      for _, c in pairs(modules) do
        table.insert(ret, c.path)
      end
      return ret
    end)(),

    -- section title
    section_fmt = function(name)
      return modules[name] and modules[name].title or error(string.format("unknown module %s passed to section", name))
    end,

    -- section's help tag
    helptag_fmt = function(name)
      return modules[name] and modules[name].helptag or error(string.format("unknown module %s passed to helptag_fmt", name))
    end,

    -- class/function's help tag
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
