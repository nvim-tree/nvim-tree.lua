--nvim-tree configuration for Nvim's gen_vimdoc.lua
--Returned config is injected into the above.
--Execute with `make doc`, see scripts/vimdoc.sh for details.

--gen_vimdoc keys by filename:   -- FIXME: Using f_base will confuse `_meta/protocol.lua` with `protocol.lua`
--Hence we must ensure that filenames are unique within each nvim.gen_vimdoc.Config[]

---@class (exact) Src
---@field helptag string must be globally unique
---@field section string arbitrary
---@field path string relative to root

local pre = "runtime/lua/nvim_tree/"

---@type Src[]
local srcs_config = {
  { helptag = "nvim-tree-config",                     section = "Config",                      path = pre .. "_meta/config.lua", },

  { helptag = "nvim-tree-config-sort",                section = "Config: sort",                path = pre .. "_meta/config/sort.lua", },
  { helptag = "nvim-tree-config-view",                section = "Config: view",                path = pre .. "_meta/config/view.lua", },
  { helptag = "nvim-tree-config-renderer",            section = "Config: renderer",            path = pre .. "_meta/config/renderer.lua", },
  { helptag = "nvim-tree-config-hijack-directories",  section = "Config: hijack_directories",  path = pre .. "_meta/config/hijack_directories.lua", },
  { helptag = "nvim-tree-config-update-focused-file", section = "Config: update_focused_file", path = pre .. "_meta/config/update_focused_file.lua", },
  { helptag = "nvim-tree-config-system-open",         section = "Config: system_open",         path = pre .. "_meta/config/system_open.lua", },
  { helptag = "nvim-tree-config-git",                 section = "Config: git",                 path = pre .. "_meta/config/git.lua", },
  { helptag = "nvim-tree-config-diagnostics",         section = "Config: diagnostics",         path = pre .. "_meta/config/diagnostics.lua", },
  { helptag = "nvim-tree-config-modified",            section = "Config: modified",            path = pre .. "_meta/config/modified.lua", },
  { helptag = "nvim-tree-config-filters",             section = "Config: filters",             path = pre .. "_meta/config/filters.lua", },
  { helptag = "nvim-tree-config-live-filter",         section = "Config: live_filter",         path = pre .. "_meta/config/live_filter.lua", },
  { helptag = "nvim-tree-config-filesystem-watchers", section = "Config: filesystem_watchers", path = pre .. "_meta/config/filesystem_watchers.lua", },
  { helptag = "nvim-tree-config-actions",             section = "Config: actions",             path = pre .. "_meta/config/actions.lua", },
  { helptag = "nvim-tree-config-trash",               section = "Config: trash",               path = pre .. "_meta/config/trash.lua", },
  { helptag = "nvim-tree-config-tab",                 section = "Config: tab",                 path = pre .. "_meta/config/tab.lua", },
  { helptag = "nvim-tree-config-notify",              section = "Config: notify",              path = pre .. "_meta/config/notify.lua", },
  { helptag = "nvim-tree-config-bookmarks",           section = "Config: bookmarks",           path = pre .. "_meta/config/bookmarks.lua", },
  { helptag = "nvim-tree-config-help",                section = "Config: help",                path = pre .. "_meta/config/help.lua", },
  { helptag = "nvim-tree-config-ui",                  section = "Config: ui",                  path = pre .. "_meta/config/ui.lua", },
  { helptag = "nvim-tree-config-experimental",        section = "Config: experimental",        path = pre .. "_meta/config/experimental.lua", },
  { helptag = "nvim-tree-config-log",                 section = "Config: log",                 path = pre .. "_meta/config/log.lua", },

  { helptag = "nvim-tree-config-default",             section = "Config: Default",             path = pre .. "_meta/config/default.lua", },

  { helptag = "nvim-tree-api",                        section = "PLACEHOLDER",                 path = "runtime/lua/placeholder.lua", },
}

---@type Src[]
local srcs_api = {
  { helptag = "nvim-tree-api",           section = "API",           path = pre .. "api.lua", },

  { helptag = "nvim-tree-api-commands",  section = "API: commands", path = pre .. "_meta/api/commands.lua", },
  { helptag = "nvim-tree-api-events",    section = "API: events",   path = pre .. "_meta/api/events.lua", },
  { helptag = "nvim-tree-api-filter",    section = "API: filter",   path = pre .. "_meta/api/filter.lua", },
  { helptag = "nvim-tree-api-fs",        section = "API: fs",       path = pre .. "_meta/api/fs.lua", },
  { helptag = "nvim-tree-api-git",       section = "API: git",      path = pre .. "_meta/api/git.lua", },
  { helptag = "nvim-tree-api-health",    section = "API: health",   path = pre .. "_meta/api/health.lua", },
  { helptag = "nvim-tree-api-map",       section = "API: map",      path = pre .. "_meta/api/map.lua", },
  { helptag = "nvim-tree-api-marks",     section = "API: marks",    path = pre .. "_meta/api/marks.lua", },
  { helptag = "nvim-tree-api-node",      section = "API: node",     path = pre .. "_meta/api/node.lua", },
  { helptag = "nvim-tree-api-tree",      section = "API: tree",     path = pre .. "_meta/api/tree.lua", },

  { helptag = "nvim-tree-api-decorator", section = "PLACEHOLDER",   path = "runtime/lua/placeholder.lua", },
}

---@type Src[]
local srcs_class = {
  { helptag = "nvim-tree-api-decorator", section = "API: Decorator", path = pre .. "_meta/api/decorator.lua", },
  { helptag = "nvim-tree-api-class",     section = "API: Class",     path = pre .. "classic.lua", },
}

---Map paths to file names
---File names are the unique key that gen_vimdoc.lua uses
---@param srcs Src[]
---@return string[] file names
local function section_order(srcs)
  return vim.tbl_map(function(src)
    return vim.fn.fnamemodify(src.path, ":t")
  end, srcs)
end

---Extract paths
---@param srcs Src[]
---@return string[] file names
local function files(srcs)
  return vim.tbl_map(function(src)
    return src.path
  end, srcs)
end

---Find a Src or error.
---Name is the (sometimes specifically hardcoded) mangled case filename with .lua stripped
---@param name string
---@param srcs Src[]
---@return Src?
local function src_by_name(name, srcs)
  for _, s in ipairs(srcs) do
    if s.path:match(name:lower() .. ".lua$") then
      return s
    end
  end
  error(string.format("\n\nPath for lower, extension stripped file name='%s' not found in\nsrcs=%s\n", name, vim.inspect(srcs)))
end

-- generator doesn't strip _meta
local function normalise_module(fun)
  fun.module = fun.module and fun.module:gsub("._meta", "", 1) or nil
end

---HACK
---Problem:
--- Generator generates fields for a class' methods.
--- This is a problem as method fields don't have a module and aren't transformed.
--- Method field fun only contains: classvar, desc, name and (function) type
---Solution:
--- Collect a map of "class:method" to modules when the real method passes through fn_xform
--- This works as the real method function is processed before the field method.
---@type table<string, string>
local modules_by_method = {}

-- @type nvim.gen_vimdoc.Config[]
return {
  -- Config
  {
    filename = "nvim-tree-lua.txt",
    section_order = section_order(srcs_config),
    files = files(srcs_config),
    section_fmt = function(name) return src_by_name(name, srcs_config).section end,
    helptag_fmt = function(name) return src_by_name(name, srcs_config).helptag end,
  },
  -- API
  {
    filename = "nvim-tree-lua.txt",
    section_order = section_order(srcs_api),
    files = files(srcs_api),
    section_fmt = function(name) return src_by_name(name, srcs_api).section end,
    helptag_fmt = function(name) return src_by_name(name, srcs_api).helptag end,

    -- strip module from the name
    fn_xform = function(fun)
      normalise_module(fun)
      fun.name = fun.name:gsub("^" .. fun.module .. "%.", "", 1)
    end,
  },
  -- Classes
  {
    filename = "nvim-tree-lua.txt",
    section_order = section_order(srcs_class),
    files = files(srcs_class),
    section_fmt = function(name) return src_by_name(name, srcs_class).section end,
    helptag_fmt = function(name) return src_by_name(name, srcs_class).helptag end,

    fn_xform = function(fun)
      -- strip module from name and record the module for the method
      normalise_module(fun)

      -- strip the class file from the module
      fun.module = fun.module:gsub("%.[^%.]*$", "", 1)

      -- strip module from name and record the module for the method
      modules_by_method[fun.classvar .. ":" .. fun.name] = fun.module
      print(vim.inspect(modules_by_method))
    end,

    -- fn_helptag_fmt_common derived
    --  module prepended to classes
    --  module is fetched from modules_by_method when fun.module unavailable
    fn_helptag_fmt = function(fun)
      local fn_sfx = fun.table and "" or "()"
      local module = fun.module or modules_by_method[fun.classvar .. ":" .. fun.name]
      return string.format("%s.%s:%s%s", module, fun.classvar, fun.name, fn_sfx)
    end,
  },
}
