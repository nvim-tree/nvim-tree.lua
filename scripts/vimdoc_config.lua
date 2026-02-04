--nvim-tree configuration for Nvim's gen_vimdoc.lua
--Returned config is injected into the above.
--Execute with `make doc`, see scripts/vimdoc.sh for details.

--gen_vimdoc keys by filename:   -- FIXME: Using f_base will confuse `_meta/protocol.lua` with `protocol.lua`
--Hence we must ensure that filenames are unique within each nvim.gen_vimdoc.Config[]

---@class (exact) Src
---@field helptag string must be globally unique
---@field section string arbitrary
---@field path string relative to cwd

local base = "runtime/lua/nvim_tree/"
local placeholder = "runtime/lua/placeholder.lua"

---@type Src[]
local srcs_config = {
  { helptag = "nvim-tree-config",                     section = "Config",                      path = base .. "_meta/config.lua", },

  { helptag = "nvim-tree-config-sort",                section = "Config: sort",                path = base .. "_meta/config/sort.lua", },
  { helptag = "nvim-tree-config-view",                section = "Config: view",                path = base .. "_meta/config/view.lua", },
  { helptag = "nvim-tree-config-renderer",            section = "Config: renderer",            path = base .. "_meta/config/renderer.lua", },
  { helptag = "nvim-tree-config-hijack-directories",  section = "Config: hijack_directories",  path = base .. "_meta/config/hijack_directories.lua", },
  { helptag = "nvim-tree-config-update-focused-file", section = "Config: update_focused_file", path = base .. "_meta/config/update_focused_file.lua", },
  { helptag = "nvim-tree-config-system-open",         section = "Config: system_open",         path = base .. "_meta/config/system_open.lua", },
  { helptag = "nvim-tree-config-git",                 section = "Config: git",                 path = base .. "_meta/config/git.lua", },
  { helptag = "nvim-tree-config-diagnostics",         section = "Config: diagnostics",         path = base .. "_meta/config/diagnostics.lua", },
  { helptag = "nvim-tree-config-modified",            section = "Config: modified",            path = base .. "_meta/config/modified.lua", },
  { helptag = "nvim-tree-config-filters",             section = "Config: filters",             path = base .. "_meta/config/filters.lua", },
  { helptag = "nvim-tree-config-live-filter",         section = "Config: live_filter",         path = base .. "_meta/config/live_filter.lua", },
  { helptag = "nvim-tree-config-filesystem-watchers", section = "Config: filesystem_watchers", path = base .. "_meta/config/filesystem_watchers.lua", },
  { helptag = "nvim-tree-config-actions",             section = "Config: actions",             path = base .. "_meta/config/actions.lua", },
  { helptag = "nvim-tree-config-trash",               section = "Config: trash",               path = base .. "_meta/config/trash.lua", },
  { helptag = "nvim-tree-config-tab",                 section = "Config: tab",                 path = base .. "_meta/config/tab.lua", },
  { helptag = "nvim-tree-config-notify",              section = "Config: notify",              path = base .. "_meta/config/notify.lua", },
  { helptag = "nvim-tree-config-bookmarks",           section = "Config: bookmarks",           path = base .. "_meta/config/bookmarks.lua", },
  { helptag = "nvim-tree-config-help",                section = "Config: help",                path = base .. "_meta/config/help.lua", },
  { helptag = "nvim-tree-config-ui",                  section = "Config: ui",                  path = base .. "_meta/config/ui.lua", },
  { helptag = "nvim-tree-config-experimental",        section = "Config: experimental",        path = base .. "_meta/config/experimental.lua", },
  { helptag = "nvim-tree-config-log",                 section = "Config: log",                 path = base .. "_meta/config/log.lua", },

  { helptag = "nvim-tree-config-default",             section = "Config: Default",             path = base .. "_meta/config/default.lua", },

  { helptag = "nvim-tree-api",                        section = "PLACEHOLDER",                 path = placeholder, },
}

---@type Src[]
local srcs_api = {
  { helptag = "nvim-tree-api",          section = "API",           path = base .. "api.lua", },

  { helptag = "nvim-tree-api-commands", section = "API: commands", path = base .. "_meta/api/commands.lua", },
  { helptag = "nvim-tree-api-events",   section = "API: events",   path = base .. "_meta/api/events.lua", },
  { helptag = "nvim-tree-api-filter",   section = "API: filter",   path = base .. "_meta/api/filter.lua", },
  { helptag = "nvim-tree-api-fs",       section = "API: fs",       path = base .. "_meta/api/fs.lua", },
  { helptag = "nvim-tree-api-git",      section = "API: git",      path = base .. "_meta/api/git.lua", },
  { helptag = "nvim-tree-api-health",   section = "API: health",   path = base .. "_meta/api/health.lua", },
  { helptag = "nvim-tree-api-map",      section = "API: map",      path = base .. "_meta/api/map.lua", },
  { helptag = "nvim-tree-api-marks",    section = "API: marks",    path = base .. "_meta/api/marks.lua", },
  { helptag = "nvim-tree-api-node",     section = "API: node",     path = base .. "_meta/api/node.lua", },
  { helptag = "nvim-tree-api-tree",     section = "API: tree",     path = base .. "_meta/api/tree.lua", },

  { helptag = "nvim-tree-class",        section = "PLACEHOLDER",   path = placeholder, },
}

---@type Src[]
local srcs_class = {
  { helptag = "nvim-tree-class",                   section = "Class: Class",             path = base .. "classic.lua", },
  { helptag = "nvim-tree-class-decorator",         section = "Class: Decorator",         path = base .. "_meta/api/decorator.lua", },
  { helptag = "nvim-tree-class-decorator-example", section = "Class: Decorator example", path = base .. "_meta/api/decorator_example.lua", },
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

    fn_xform = function(fun)
      if (fun.module) then
        normalise_module(fun)

        -- remove the module prefix from the left aligned function name
        -- default fn_helptag_fmt adds it back to the help tag
        local replaced
        fun.name, replaced = fun.name:gsub("^" .. fun.module .. "%.", "", 1)
        if (replaced ~= 1) then
          error(string.format("\n\nfun.name='%s' does not start with module\nfun=%s", fun.name, vim.inspect(fun)))
        end
      end
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
      if (fun.module) then
        normalise_module(fun)

        -- strip the class file from the module
        fun.module = fun.module:gsub("%.[^%.]*$", "", 1)

        -- record the module for the method
        modules_by_method[fun.classvar .. ":" .. fun.name] = fun.module
      end
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
