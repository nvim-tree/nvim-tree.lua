---@class (exact) Module
---@field helptag string must be globally unique
---@field title string arbitrary
---@field path string relative to root
---@field file string? generated from path
---@field name string? override generated module name

---Generated within help files in this order
---@type Module[]
local modules = {
  { helptag = "nvim-tree-config",                     title = "Class: Config",                    path = "./lua/nvim_tree/_meta/config.lua", },
  { helptag = "nvim-tree-config-sort",                title = "Class: Config.Sort",               path = "./lua/nvim_tree/_meta/config/sort.lua", },
  { helptag = "nvim-tree-config-view",                title = "Class: Config.View",               path = "./lua/nvim_tree/_meta/config/view.lua", },
  { helptag = "nvim-tree-config-renderer",            title = "Class: Config.Renderer",           path = "./lua/nvim_tree/_meta/config/renderer.lua", },
  { helptag = "nvim-tree-config-hijack-directories",  title = "Class: Config.HijackDirectories",  path = "./lua/nvim_tree/_meta/config/hijack_directories.lua", },
  { helptag = "nvim-tree-config-update-focused-file", title = "Class: Config.UpdateFocusedFile",  path = "./lua/nvim_tree/_meta/config/update_focused_file.lua", },
  { helptag = "nvim-tree-config-system-open",         title = "Class: Config.SystemOpen",         path = "./lua/nvim_tree/_meta/config/system_open.lua", },
  { helptag = "nvim-tree-config-git",                 title = "Class: Config.Git",                path = "./lua/nvim_tree/_meta/config/git.lua", },
  { helptag = "nvim-tree-config-diagnostics",         title = "Class: Config.Diagnostics",        path = "./lua/nvim_tree/_meta/config/diagnostics.lua", },
  { helptag = "nvim-tree-config-modified",            title = "Class: Config.Modified",           path = "./lua/nvim_tree/_meta/config/modified.lua", },
  { helptag = "nvim-tree-config-filters",             title = "Class: Config.Filters",            path = "./lua/nvim_tree/_meta/config/filters.lua", },
  { helptag = "nvim-tree-config-live-filter",         title = "Class: Config.LiveFilter",         path = "./lua/nvim_tree/_meta/config/live_filter.lua", },
  { helptag = "nvim-tree-config-filesystem-watchers", title = "Class: Config.FilesystemWatchers", path = "./lua/nvim_tree/_meta/config/filesystem_watchers.lua", },
  { helptag = "nvim-tree-config-actions",             title = "Class: Config.Actions",            path = "./lua/nvim_tree/_meta/config/actions.lua", },
  { helptag = "nvim-tree-config-trash",               title = "Class: Config.Trash",              path = "./lua/nvim_tree/_meta/config/trash.lua", },
  { helptag = "nvim-tree-config-tab",                 title = "Class: Config.Tab",                path = "./lua/nvim_tree/_meta/config/tab.lua", },
  { helptag = "nvim-tree-config-notify",              title = "Class: Config.Notify",             path = "./lua/nvim_tree/_meta/config/notify.lua", },
  { helptag = "nvim-tree-config-bookmarks",           title = "Class: Config.Bookmarks",          path = "./lua/nvim_tree/_meta/config/bookmarks.lua", },
  { helptag = "nvim-tree-config-help",                title = "Class: Config.Help",               path = "./lua/nvim_tree/_meta/config/help.lua", },
  { helptag = "nvim-tree-config-ui",                  title = "Class: Config.UI",                 path = "./lua/nvim_tree/_meta/config/ui.lua",                  name = "UI", },
  { helptag = "nvim-tree-config-experimental",        title = "Class: Config.Experimental",       path = "./lua/nvim_tree/_meta/config/experimental.lua", },
  { helptag = "nvim-tree-config-log",                 title = "Class: Config.Log",                path = "./lua/nvim_tree/_meta/config/log.lua", },

  { helptag = "nvim-tree-api-config",                 title = "Lua module: nvim_tree.api.config", path = "./lua/nvim_tree/api/config/mappings.lua", },
  { helptag = "nvim-tree-api-tree",                   title = "Lua module: nvim_tree.api.tree",   path = "./lua/nvim_tree/api/tree.lua", },
}

-- hydrate file names
for _, m in ipairs(modules) do
  m.file = vim.fn.fnamemodify(m.path, ":t")
end

--section name is derived by the generator as the file name with the first letter capitalised
--except for some like UI
---@type table<string, Module>
local modules_by_section = {}
for _, m in ipairs(modules) do
  local name = m.name or m.file:gsub(".lua", ""):gsub("^%l", string.upper)
  modules_by_section[name] = m
end

---@diagnostic disable-next-line: undefined-doc-name
--- @type table<string,nvim.gen_vimdoc.Config>
local config = {
  all = {
    filename = "nvim-tree-lua.txt",

    -- file is used to set order
    section_order = vim.tbl_map(function(m) return m.file end, modules),

    -- path
    files = vim.tbl_map(function(m) return m.path end, modules),

    section_fmt = function(name)
      print(string.format("section_fmt name=%s", name))
      return modules_by_section[name] and modules_by_section[name].title or error(string.format("unknown module %s passed to section_fmt", name))
    end,

    helptag_fmt = function(name)
      print(string.format("helptag_fmt name=%s", name))
      return modules_by_section[name] and modules_by_section[name].helptag or error(string.format("unknown module %s passed to helptag_fmt", name))
    end,

    -- optional, no default xform
    fn_xform = function(fun)
      -- print(string.format("fn_xform fun=%s", vim.inspect(fun)))

      if (fun.module) then
        -- generator doesn't strip meta
        -- also cascades into fn_helptag_fmt
        local module = fun.module:gsub("._meta", "", 1)

        if module ~= fun.module then
          error("unexpected _meta in module")
          print(string.format("fn_xform module: %s -> %s", fun.module, module))
        end

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
