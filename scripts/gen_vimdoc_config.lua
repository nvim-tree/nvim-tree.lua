--nvim-tree configuration for Nvim's gen_vimdoc.lua
--Returned config is injected into the above.
--See gen_vimdoc.sh

---@class (exact) Src
---@field helptag string must be globally unique
---@field section string arbitrary
---@field path string relative to root
---@field file_name? string generated from path
---@field name? string override generated name
---@field append_only? boolean follows previous section

---Help txt is deleted from first tag down and generated content is appended.
---@type Src[]
local srcs = {
  { helptag = "nvim-tree-config",                     section = "Config",                      path = "./lua/nvim_tree/_meta/config.lua", },
  { helptag = "nvim-tree-config-sort",                section = "Config: sort",                path = "./lua/nvim_tree/_meta/config/sort.lua", },
  { helptag = "nvim-tree-config-view",                section = "Config: view",                path = "./lua/nvim_tree/_meta/config/view.lua", },
  { helptag = "nvim-tree-config-renderer",            section = "Config: renderer",            path = "./lua/nvim_tree/_meta/config/renderer.lua", },
  { helptag = "nvim-tree-config-hijack-directories",  section = "Config: hijack_directories",  path = "./lua/nvim_tree/_meta/config/hijack_directories.lua", },
  { helptag = "nvim-tree-config-update-focused-file", section = "Config: update_focused_file", path = "./lua/nvim_tree/_meta/config/update_focused_file.lua", },
  { helptag = "nvim-tree-config-system-open",         section = "Config: system_open",         path = "./lua/nvim_tree/_meta/config/system_open.lua", },
  { helptag = "nvim-tree-config-git",                 section = "Config: git",                 path = "./lua/nvim_tree/_meta/config/git.lua", },
  { helptag = "nvim-tree-config-diagnostics",         section = "Config: diagnostics",         path = "./lua/nvim_tree/_meta/config/diagnostics.lua", },
  { helptag = "nvim-tree-config-modified",            section = "Config: modified",            path = "./lua/nvim_tree/_meta/config/modified.lua", },
  { helptag = "nvim-tree-config-filters",             section = "Config: filters",             path = "./lua/nvim_tree/_meta/config/filters.lua", },
  { helptag = "nvim-tree-config-live-filter",         section = "Config: live_filter",         path = "./lua/nvim_tree/_meta/config/live_filter.lua", },
  { helptag = "nvim-tree-config-filesystem-watchers", section = "Config: filesystem_watchers", path = "./lua/nvim_tree/_meta/config/filesystem_watchers.lua", },
  { helptag = "nvim-tree-config-actions",             section = "Config: actions",             path = "./lua/nvim_tree/_meta/config/actions.lua", },
  { helptag = "nvim-tree-config-trash",               section = "Config: trash",               path = "./lua/nvim_tree/_meta/config/trash.lua", },
  { helptag = "nvim-tree-config-tab",                 section = "Config: tab",                 path = "./lua/nvim_tree/_meta/config/tab.lua", },
  { helptag = "nvim-tree-config-notify",              section = "Config: notify",              path = "./lua/nvim_tree/_meta/config/notify.lua", },
  { helptag = "nvim-tree-config-bookmarks",           section = "Config: bookmarks",           path = "./lua/nvim_tree/_meta/config/bookmarks.lua", },
  { helptag = "nvim-tree-config-help",                section = "Config: help",                path = "./lua/nvim_tree/_meta/config/help.lua", },
  { helptag = "nvim-tree-config-ui",                  section = "Config: ui",                  path = "./lua/nvim_tree/_meta/config/ui.lua",                  name = "UI", },
  { helptag = "nvim-tree-config-experimental",        section = "Config: experimental",        path = "./lua/nvim_tree/_meta/config/experimental.lua", },
  { helptag = "nvim-tree-config-log",                 section = "Config: log",                 path = "./lua/nvim_tree/_meta/config/log.lua", },

  { helptag = "nvim-tree-config-default",             section = "Config: Default",             path = "./lua/nvim_tree/_meta/config/default.lua", },

  { helptag = "nvim-tree-api",                        section = "API",                         path = "./lua/nvim_tree/_meta/api.lua", },

  { helptag = "nvim-tree-api-commands",               section = "API: commands",               path = "./lua/nvim_tree/_meta/api/commands.lua", },
  { helptag = "nvim-tree-api-events",                 section = "API: events",                 path = "./lua/nvim_tree/_meta/api/events.lua", },
  { helptag = "nvim-tree-api-filter",                 section = "API: filter",                 path = "./lua/nvim_tree/_meta/api/filter.lua", },
  { helptag = "nvim-tree-api-fs",                     section = "API: fs",                     path = "./lua/nvim_tree/_meta/api/fs.lua", },
  { helptag = "nvim-tree-api-health",                 section = "API: health",                 path = "./lua/nvim_tree/_meta/api/health.lua", },
  { helptag = "nvim-tree-api-map",                    section = "API: map",                    path = "./lua/nvim_tree/_meta/api/map.lua", },
  { helptag = "nvim-tree-api-marks",                  section = "API: marks",                  path = "./lua/nvim_tree/_meta/api/marks.lua", },
  { helptag = "nvim-tree-api-node",                   section = "API: node",                   path = "./lua/nvim_tree/_meta/api/node.lua", },
  { helptag = "nvim-tree-api-tree",                   section = "API: tree",                   path = "./lua/nvim_tree/_meta/api/tree.lua", },
}

-- hydrate file names
for _, m in ipairs(srcs) do
  m.file_name = vim.fn.fnamemodify(m.path, ":t")
end

--name is derived by the generator as the file name with the first letter capitalised
--except for some like UI which are overridden in srcs
---@type table<string, Src>
local srcs_by_name = {}
for _, m in ipairs(srcs) do
  local name = m.name or m.file_name:gsub(".lua", ""):gsub("^%l", string.upper)
  srcs_by_name[name] = m
end

-- @type table<string,nvim.gen_vimdoc.Config>
local config = {
  all = {
    filename = "nvim-tree-lua.txt",

    -- source file name is used to set order
    section_order = vim.tbl_map(function(src) return src.file_name end, srcs),

    -- path
    files = vim.tbl_map(function(src) return src.path end, srcs),

    append_only = vim.tbl_map(function(src) return src.append_only and src.file_name or nil end, srcs),

    section_fmt = function(name)
      print(string.format("section_fmt name=%s", name))
      return srcs_by_name[name] and srcs_by_name[name].section or
        error(string.format("unknown name %s passed to section_fmt", name))
    end,

    helptag_fmt = function(name)
      print(string.format("helptag_fmt name=%s", name))
      return srcs_by_name[name] and srcs_by_name[name].helptag or
        error(string.format("unknown name %s passed to helptag_fmt", name))
    end,

    -- optional, no default xform
    fn_xform = function(fun)
      print(string.format("fn_xform fun=%s", vim.inspect(fun)))

      if (fun.module) then
        -- generator doesn't strip meta
        -- also cascades into fn_helptag_fmt
        local module = fun.module:gsub("._meta", "", 1)

        -- remove the API prefix from the left aligned function name
        -- this will cascade into fn_helptag_fmt, which will apply the module prefix anyway
        local name, replaced = fun.name:gsub("^" .. module .. "%.", "", 1)
        if (replaced ~= 1) then
          error(string.format("function name does not start with module: %s", vim.inspect(fun)))
        end

        print(string.format("fn_xform name: %s -> %s", fun.name, name))

        fun.module = module
        fun.name = name
      end
    end,
  }
}

return config
