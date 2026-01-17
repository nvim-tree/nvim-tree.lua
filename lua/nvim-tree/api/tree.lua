---@meta
local nvim_tree = { api = { tree = {} } }

---@class nvim_tree.api.tree.open.Opts
---@inlinedoc
---@field path string|nil path
---@field current_window boolean|nil default false
---@field winid number|nil
---@field find_file boolean|nil default false
---@field update_root boolean|nil default false

---@param opts? nvim_tree.api.tree.open.Opts
function nvim_tree.api.tree.open(opts) end

---TODO #3088 descriptions are needed to properly format the functions
function nvim_tree.api.tree.focus() end

---@class nvim_tree.api.tree.toggle.Opts
---@inlinedoc
---@field path string|nil
---@field current_window boolean|nil default false
---@field winid number|nil
---@field find_file boolean|nil default false
---@field update_root boolean|nil default false
---@field focus boolean|nil default true

function nvim_tree.api.tree.toggle(opts) end

function nvim_tree.api.tree.close() end

function nvim_tree.api.tree.close_in_this_tab() end

function nvim_tree.api.tree.close_in_all_tabs() end

function nvim_tree.api.tree.reload() end

---@class nvim_tree.api.tree.resize.Opts
---@inlinedoc
---@field width string|function|number|table|nil
---@field absolute number|nil
---@field relative number|nil

function nvim_tree.api.tree.resize(opts) end

function nvim_tree.api.tree.change_root() end

function nvim_tree.api.tree.change_root_to_node() end

function nvim_tree.api.tree.change_root_to_parent() end

function nvim_tree.api.tree.get_node_under_cursor() end

function nvim_tree.api.tree.get_nodes() end

---@class nvim_tree.api.tree.find_file.Opts
---@inlinedoc
---@field buf string|number|nil
---@field open boolean|nil default false
---@field current_window boolean|nil default false
---@field winid number|nil
---@field update_root boolean|nil default false
---@field focus boolean|nil default false

function nvim_tree.api.tree.find_file(opts) end

function nvim_tree.api.tree.search_node() end

---@class nvim_tree.api.tree.collapse.Opts
---@inlinedoc
---@field keep_buffers boolean|nil default false

function nvim_tree.api.tree.collapse_all(opts) end

---@class nvim_tree.api.tree.expand.Opts
---@inlinedoc
---@field expand_until (fun(expansion_count: integer, node: Node): boolean)|nil

function nvim_tree.api.tree.expand_all(opts) end

function nvim_tree.api.tree.toggle_enable_filters() end

function nvim_tree.api.tree.toggle_gitignore_filter() end

function nvim_tree.api.tree.toggle_git_clean_filter() end

function nvim_tree.api.tree.toggle_no_buffer_filter() end

function nvim_tree.api.tree.toggle_custom_filter() end

function nvim_tree.api.tree.toggle_hidden_filter() end

function nvim_tree.api.tree.toggle_no_bookmark_filter() end

function nvim_tree.api.tree.toggle_help() end

function nvim_tree.api.tree.is_tree_buf() end

---@class nvim_tree.api.tree.is_visible.Opts
---@inlinedoc
---@field tabpage number|nil
---@field any_tabpage boolean|nil default false

function nvim_tree.api.tree.is_visible(opts) end

---@class nvim_tree.api.tree.winid.Opts
---@inlinedoc
---@field tabpage number|nil default nil

function nvim_tree.api.tree.winid(opts) end

require("nvim-tree.api").hydrate_tree(nvim_tree.api.tree)

return nvim_tree.api.tree
