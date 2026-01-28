--nvim-tree configuration for Nvim's gen_vimdoc.lua
--Returned config is injected into the above.
--See gen_vimdoc.sh

---@class (exact) Src
---@field helptag string must be globally unique
---@field section string arbitrary
---@field path string relative to root

---Help txt is deleted from first tag down and generated content is appended.
local pre = "runtime/lua/nvim_tree/"
---@type Src[]
local srcs = {
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

  { helptag = "nvim-tree-api",                        section = "API",                         path = pre .. "api.lua", },

  { helptag = "nvim-tree-api-commands",               section = "API: commands",               path = pre .. "_meta/api/commands.lua", },
  { helptag = "nvim-tree-api-events",                 section = "API: events",                 path = pre .. "_meta/api/events.lua", },
  { helptag = "nvim-tree-api-filter",                 section = "API: filter",                 path = pre .. "_meta/api/filter.lua", },
  { helptag = "nvim-tree-api-fs",                     section = "API: fs",                     path = pre .. "_meta/api/fs.lua", },
  { helptag = "nvim-tree-api-git",                    section = "API: git",                    path = pre .. "_meta/api/git.lua", },
  { helptag = "nvim-tree-api-health",                 section = "API: health",                 path = pre .. "_meta/api/health.lua", },
  { helptag = "nvim-tree-api-map",                    section = "API: map",                    path = pre .. "_meta/api/map.lua", },
  { helptag = "nvim-tree-api-marks",                  section = "API: marks",                  path = pre .. "_meta/api/marks.lua", },
  { helptag = "nvim-tree-api-node",                   section = "API: node",                   path = pre .. "_meta/api/node.lua", },
  { helptag = "nvim-tree-api-tree",                   section = "API: tree",                   path = pre .. "_meta/api/tree.lua", },
}

--name is derived by the generator as the path with the first letter capitalised and the extension stripped
---@type table<string, Src>
local srcs_by_name = {}
for _, m in ipairs(srcs) do
  local name = m.path:gsub("^%l", string.upper):gsub(".lua$", "")
  srcs_by_name[name] = m
end

-- @type table<string,nvim.gen_vimdoc.Config>
local config = {
  all = {
    filename = "nvim-tree-lua.txt",

    -- path, ordered
    section_order = vim.tbl_map(function(src) return src.path end, srcs),

    -- path, unordered
    files = vim.tbl_map(function(src) return src.path end, srcs),

    -- lookup by name
    section_fmt = function(name)
      return srcs_by_name[name] and srcs_by_name[name].section or error(string.format("\nUnknown name passed to section_fmt: '%s'", name))
    end,

    -- lookup by name
    helptag_fmt = function(name)
      return srcs_by_name[name] and srcs_by_name[name].helptag or error(string.format("\nUnknown name passed to helptag_fmt: '%s'", name))
    end,

    -- optional, no default xform
    fn_xform = function(fun)
      if (fun.module) then
        -- generator doesn't strip meta
        -- also cascades into fn_helptag_fmt
        local module = fun.module:gsub("._meta", "", 1)

        -- remove the API module from the left aligned function name
        -- this will cascade into fn_helptag_fmt, which will apply the module prefix anyway
        local name, replaced = fun.name:gsub("^" .. module .. "%.", "", 1)
        if (replaced ~= 1) then
          error(string.format("\nFunction name does not start with\nmodule='%s'\nfun=%s", module, vim.inspect(fun)))
        end

        fun.module = module
        fun.name = name
      end
    end,
  }
}

return config
