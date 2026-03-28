---Hydrates API meta functions with their implementations.
---For startup performance reasons, all API implementation's requires must be
---done at call time, not when this module is required.

local M = {}

---Walk the entire API, hydrating all functions with the error notification.
---Do not hydrate classes i.e. anything with a metatable.
---@param api table not properly typed to prevent LSP from referencing implementations
local function hydrate_not_setup(api)
  for k, v in pairs(api) do
    if type(v) == "function" then
      api[k] = function()
        require("nvim-tree.notify").error("nvim-tree setup not called")
      end
    elseif type(v) == "table" and not getmetatable(v) then
      hydrate_not_setup(v)
    end
  end
end

---Returns the node under the cursor.
---@return Node?
local function node_at_cursor()
  local e = require("nvim-tree.core").get_explorer()
  return e and e:get_node_at_cursor() or nil
end

---Returns the visually selected nodes, if we are in visual mode.
---@return Node[]?
local function visual_nodes()
  local utils = require("nvim-tree.utils")
  return utils.is_visual_mode() and utils.get_visual_nodes() or nil
end

---Injects:
---- n: n or node at cursor
---@param fn fun(n?: Node, ...): any
---@return fun(n?: Node, ...): any
local function _n(fn)
  return function(n, ...)
    return fn(n or node_at_cursor(), ...)
  end
end

---Injects:
---- n: visual nodes or n or node at cursor
---@param fn fun(n?: Node|Node[], ...): any
---@return fun(n?: Node|Node[], ...): any
local function _v(fn)
  return function(n, ...)
    return fn(visual_nodes() or n or node_at_cursor(), ...)
  end
end

---Injects:
---- e: Explorer instance
---Does nothing when no explorer instance.
---@param fn fun(e: Explorer, ...): any
---@return fun(e: Explorer, ...): any
local function e_(fn)
  return function(...)
    local e = require("nvim-tree.core").get_explorer()
    if e then
      return fn(e, ...)
    end
  end
end

---Injects:
---- e: Explorer instance
---- n: n or node at cursor
---Does nothing when no explorer instance.
---@param fn fun(e: Explorer, n?: Node, ...): any
---@return fun(e: Explorer, n?: Node, ...): any
local function en(fn)
  return function(n, ...)
    local e = require("nvim-tree.core").get_explorer()
    if e then
      return fn(e, n or node_at_cursor(), ...)
    end
  end
end

---Injects:
---- e: Explorer instance
---- n: visual nodes or n or node at cursor
---Does nothing when no explorer instance.
---@param fn fun(e: Explorer, n?: Node|Node[], ...): any
---@return fun(e: Explorer, n?: Node|Node[], ...): any
local function ev(fn)
  return function(n, ...)
    local e = require("nvim-tree.core").get_explorer()
    if e then
      return fn(e, visual_nodes() or n or node_at_cursor(), ...)
    end
  end
end

---NOP function wrapper, exists for formatting purposes only.
---@param fn fun(...): any
---@return fun(...): any
local function __(fn)
  return function(...)
    return fn(...)
  end
end

---Hydrates API meta functions pre-setup:
--- Pre-setup functions will be hydrated with their implementation.
--- Post-setup functions will notify error: "nvim-tree setup not called"
--- All classes will be hydrated with their implementations.
---Called once when api is first required
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate_pre_setup(api)
  hydrate_not_setup(api)

  api.appearance.hi_test    = __(function() require("nvim-tree.appearance.hi-test")() end)

  api.commands.get          = __(function() return require("nvim-tree.commands").get() end)

  api.config.default        = __(function() return require("nvim-tree.config").d_clone() end)

  api.events.subscribe      = __(function(event_name, handler) require("nvim-tree.events").subscribe(event_name, handler) end)

  api.map.keymap.default    = __(function() return require("nvim-tree.keymap").get_keymap_default() end)
  api.map.on_attach.default = __(function(bufnr) require("nvim-tree.keymap").on_attach_default(bufnr) end)

  api.Decorator             = require("nvim-tree.renderer.decorator")

  -- Map any legacy functions to implementations above or to meta
  require("nvim-tree.legacy").map_api(api)
end

---Re-hydrates all API functions with implementations, replacing any "nvim-tree setup not called" error functions.
---Called explicitly after nvim-tree setup
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate_post_setup(api)
  api.config.global                            = __(function() return require("nvim-tree.config").g_clone() end)
  api.config.user                              = __(function() return require("nvim-tree.config").u_clone() end)

  api.filter.custom.toggle                     = e_(function(e) e.filters:toggle("custom") end)
  api.filter.dotfiles.toggle                   = e_(function(e) e.filters:toggle("dotfiles") end)
  api.filter.git.clean.toggle                  = e_(function(e) e.filters:toggle("git_clean") end)
  api.filter.git.ignored.toggle                = e_(function(e) e.filters:toggle("git_ignored") end)
  api.filter.live.clear                        = e_(function(e) e.live_filter:clear_filter() end)
  api.filter.live.start                        = e_(function(e) e.live_filter:start_filtering() end)
  api.filter.no_bookmark.toggle                = e_(function(e) e.filters:toggle("no_bookmark") end)
  api.filter.no_buffer.toggle                  = e_(function(e) e.filters:toggle("no_buffer") end)
  api.filter.toggle                            = e_(function(e) e.filters:toggle() end)

  api.fs.clear_clipboard                       = e_(function(e) e.clipboard:clear_clipboard() end)
  api.fs.copy.absolute_path                    = en(function(e, n) e.clipboard:copy_absolute_path(n) end)
  api.fs.copy.basename                         = en(function(e, n) e.clipboard:copy_basename(n) end)
  api.fs.copy.filename                         = en(function(e, n) e.clipboard:copy_filename(n) end)
  api.fs.copy.node                             = ev(function(e, n) e.clipboard:copy(n) end)
  api.fs.copy.relative_path                    = en(function(e, n) e.clipboard:copy_path(n) end)
  api.fs.create                                = _n(function(n) require("nvim-tree.actions.fs.create-file").fn(n) end)
  api.fs.cut                                   = ev(function(e, n) e.clipboard:cut(n) end)
  api.fs.paste                                 = en(function(e, n) e.clipboard:paste(n) end)
  api.fs.print_clipboard                       = e_(function(e) e.clipboard:print_clipboard() end)
  api.fs.remove                                = _v(function(n) require("nvim-tree.actions.fs.remove-file").fn(n) end)
  api.fs.rename                                = _n(function(n) require("nvim-tree.actions.fs.rename-file").rename_node(n) end)
  api.fs.rename_basename                       = _n(function(n) require("nvim-tree.actions.fs.rename-file").rename_basename(n) end)
  api.fs.rename_full                           = _n(function(n) require("nvim-tree.actions.fs.rename-file").rename_full(n) end)
  api.fs.rename_node                           = _n(function(n) require("nvim-tree.actions.fs.rename-file").rename_node(n) end)
  api.fs.rename_sub                            = _n(function(n) require("nvim-tree.actions.fs.rename-file").rename_sub(n) end)
  api.fs.trash                                 = _v(function(n) require("nvim-tree.actions.fs.trash").fn(n) end)

  api.git.reload                               = e_(function(e) e:reload_git() end)

  api.map.keymap.current                       = __(function() return require("nvim-tree.keymap").get_keymap() end)

  api.marks.bulk.delete                        = e_(function(e) e.marks:bulk_delete() end)
  api.marks.bulk.move                          = e_(function(e) e.marks:bulk_move() end)
  api.marks.bulk.trash                         = e_(function(e) e.marks:bulk_trash() end)
  api.marks.clear                              = e_(function(e) e.marks:clear() end)
  api.marks.get                                = en(function(e, n) return e.marks:get(n) end)
  api.marks.list                               = e_(function(e) return e.marks:list() end)
  api.marks.navigate.next                      = e_(function(e) e.marks:navigate_next() end)
  api.marks.navigate.prev                      = e_(function(e) e.marks:navigate_prev() end)
  api.marks.navigate.select                    = e_(function(e) e.marks:navigate_select() end)
  api.marks.toggle                             = ev(function(e, n) e.marks:toggle(n) end)

  api.node.buffer.delete                       = _n(function(n, opts) require("nvim-tree.actions.node.buffer").delete(n, opts) end)
  api.node.buffer.wipe                         = _n(function(n, opts) require("nvim-tree.actions.node.buffer").wipe(n, opts) end)
  api.node.collapse                            = _n(function(n, opts) require("nvim-tree.actions.tree.collapse").node(n, opts) end)
  api.node.expand                              = en(function(e, n, opts) e:expand_node(n, opts) end)
  api.node.navigate.diagnostics.next           = __(function() require("nvim-tree.actions.moves.item").diagnostics_next() end)
  api.node.navigate.diagnostics.next_recursive = __(function() require("nvim-tree.actions.moves.item").diagnostics_next_recursive() end)
  api.node.navigate.diagnostics.prev           = __(function() require("nvim-tree.actions.moves.item").diagnostics_prev() end)
  api.node.navigate.diagnostics.prev_recursive = __(function() require("nvim-tree.actions.moves.item").diagnostics_prev_recursive() end)
  api.node.navigate.git.next                   = __(function() require("nvim-tree.actions.moves.item").git_next() end)
  api.node.navigate.git.next_recursive         = __(function() require("nvim-tree.actions.moves.item").git_next_recursive() end)
  api.node.navigate.git.next_skip_gitignored   = __(function() require("nvim-tree.actions.moves.item").git_next_skip_gitignored() end)
  api.node.navigate.git.prev                   = __(function() require("nvim-tree.actions.moves.item").git_prev() end)
  api.node.navigate.git.prev_recursive         = __(function() require("nvim-tree.actions.moves.item").git_prev_recursive() end)
  api.node.navigate.git.prev_skip_gitignored   = __(function() require("nvim-tree.actions.moves.item").git_prev_skip_gitignored() end)
  api.node.navigate.opened.next                = __(function() require("nvim-tree.actions.moves.item").opened_next() end)
  api.node.navigate.opened.prev                = __(function() require("nvim-tree.actions.moves.item").opened_prev() end)
  api.node.navigate.parent                     = _n(function(n) require("nvim-tree.actions.moves.parent").move(n) end)
  api.node.navigate.parent_close               = _n(function(n) require("nvim-tree.actions.moves.parent").move_close(n) end)
  api.node.navigate.sibling.first              = _n(function(n) require("nvim-tree.actions.moves.sibling").first(n) end)
  api.node.navigate.sibling.last               = _n(function(n) require("nvim-tree.actions.moves.sibling").last(n) end)
  api.node.navigate.sibling.next               = _n(function(n) require("nvim-tree.actions.moves.sibling").next(n) end)
  api.node.navigate.sibling.prev               = _n(function(n) require("nvim-tree.actions.moves.sibling").prev(n) end)
  api.node.open.drop                           = _n(function(n) require("nvim-tree.actions.node.open-file").drop(n) end)
  api.node.open.edit                           = _n(function(n) require("nvim-tree.actions.node.open-file").edit(n) end)
  api.node.open.horizontal                     = _n(function(n) require("nvim-tree.actions.node.open-file").horizontal(n) end)
  api.node.open.horizontal_no_picker           = _n(function(n) require("nvim-tree.actions.node.open-file").horizontal_no_picker(n) end)
  api.node.open.no_window_picker               = _n(function(n) require("nvim-tree.actions.node.open-file").no_window_picker(n) end)
  api.node.open.preview                        = _n(function(n) require("nvim-tree.actions.node.open-file").preview(n) end)
  api.node.open.preview_no_picker              = _n(function(n) require("nvim-tree.actions.node.open-file").preview_no_picker(n) end)
  api.node.open.replace_tree_buffer            = _n(function(n) require("nvim-tree.actions.node.open-file").replace_tree_buffer(n) end)
  api.node.open.tab                            = _n(function(n) require("nvim-tree.actions.node.open-file").tab(n) end)
  api.node.open.tab_drop                       = _n(function(n) require("nvim-tree.actions.node.open-file").tab_drop(n) end)
  api.node.open.toggle_group_empty             = _n(function(n) require("nvim-tree.actions.node.open-file").toggle_group_empty(n) end)
  api.node.open.vertical                       = _n(function(n) require("nvim-tree.actions.node.open-file").vertical(n) end)
  api.node.open.vertical_no_picker             = _n(function(n) require("nvim-tree.actions.node.open-file").vertical_no_picker(n) end)
  api.node.run.cmd                             = _n(function(n) require("nvim-tree.actions.node.run-command").run_file_command(n) end)
  api.node.run.system                          = _n(function(n) require("nvim-tree.actions.node.system-open").fn(n) end)
  api.node.show_info_popup                     = _n(function(n) require("nvim-tree.actions.node.file-popup").toggle_file_info(n) end)

  api.tree.change_root                         = __(function(path) require("nvim-tree.actions.tree.change-dir").fn(path) end)
  api.tree.change_root_to_node                 = en(function(e, n) e:change_dir_to_node(n) end)
  api.tree.change_root_to_parent               = en(function(e, n) e:dir_up(n) end)
  api.tree.close                               = __(function() require("nvim-tree.view").close() end)
  api.tree.close_in_all_tabs                   = __(function() require("nvim-tree.view").close_all_tabs() end)
  api.tree.close_in_this_tab                   = __(function() require("nvim-tree.view").close_this_tab_only() end)
  api.tree.collapse_all                        = __(function(opts) require("nvim-tree.actions.tree.collapse").all(opts) end)
  api.tree.expand_all                          = en(function(e, n, opts) e:expand_all(n, opts) end)
  api.tree.find_file                           = __(function(opts) require("nvim-tree.actions.tree.find-file").fn(opts) end)
  api.tree.focus                               = __(function(opts) require("nvim-tree.actions.tree.open").fn(opts) end)
  api.tree.get_node_under_cursor               = en(function(e) return e:get_node_at_cursor() end)
  api.tree.get_nodes                           = en(function(e) return e:get_nodes() end)
  api.tree.is_tree_buf                         = __(function(bufnr) return require("nvim-tree.utils").is_nvim_tree_buf(bufnr) end)
  api.tree.is_visible                          = __(function(opts) return require("nvim-tree.view").is_visible(opts) end)
  api.tree.open                                = __(function(opts) require("nvim-tree.actions.tree.open").fn(opts) end)
  api.tree.reload                              = e_(function(e) e:reload_explorer() end)
  api.tree.reload_git                          = e_(function(e) e:reload_git() end)
  api.tree.resize                              = __(function(opts) require("nvim-tree.actions.tree.resize").fn(opts) end)
  api.tree.search_node                         = __(function() require("nvim-tree.actions.finders.search-node").fn() end)
  api.tree.toggle                              = __(function(opts) require("nvim-tree.actions.tree.toggle").fn(opts) end)
  api.tree.toggle_help                         = __(function() require("nvim-tree.help").toggle() end)
  api.tree.winid                               = __(function(opts) return require("nvim-tree.view").winid(opts) end)

  -- Map all legacy functions to implementations
  require("nvim-tree.legacy").map_api(api)
end

return M
