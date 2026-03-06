---Hydrates all API functions with concrete implementations.
---Replace all "nvim-tree setup not called" error functions from pre.lua with their implementations.
---
---Call this after nvim-tree setup
---
---All requires must be done lazily so that requiring api post setup is cheap.

local legacy = require("nvim-tree.legacy")

local M = {}

--- convenience wrappers for lazy module requires
local function actions() return require("nvim-tree.actions") end
local function core() return require("nvim-tree.core") end
local function config() return require("nvim-tree.config") end
local function help() return require("nvim-tree.help") end
local function keymap() return require("nvim-tree.keymap") end
local function utils() return require("nvim-tree.utils") end
local function view() return require("nvim-tree.view") end

---Return a function wrapper that calls fn.
---Injects node or node at cursor as first argument.
---Passes other arguments verbatim.
---@param fn fun(n?: Node, ...): any
---@return fun(n?: Node, ...): any
local function _n(fn)
  return function(n, ...)
    if not n then
      local e = core().get_explorer()
      n = e and e:get_node_at_cursor() or nil
    end
    return fn(n, ...)
  end
end

---Return a function wrapper that calls fn.
---Does nothing when no explorer instance.
---Injects an explorer instance as first arg.
---Passes other arguments verbatim.
---@param fn fun(e: Explorer, ...): any
---@return fun(e: Explorer, ...): any
local function e_(fn)
  return function(...)
    local e = core().get_explorer()
    if e then
      return fn(e, ...)
    end
  end
end

---Return a function wrapper that calls fn.
---Does nothing when no explorer instance.
---Injects an explorer instance as first arg.
---Injects node or node at cursor as second argument.
---Passes other arguments verbatim.
---@param fn fun(e: Explorer, n?: Node, ...): any
---@return fun(e: Explorer, n?: Node, ...): any
local function en(fn)
  return function(n, ...)
    local e = core().get_explorer()
    if e then
      return fn(e, n or e:get_node_at_cursor(), ...)
    end
  end
end

---Return a function wrapper that calls fn.
---Passes arguments verbatim.
---Exists for formatting purposes only.
---@param fn fun(...): any
---@return fun(...): any
local function __(fn)
  return function(...)
    return fn(...)
  end
end

---Re-Hydrate api functions and classes post-setup
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate(api)
  api.config.global                            = __(function() return config().g_clone() end)
  api.config.user                              = __(function() return config().u_clone() end)

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
  api.fs.copy.node                             = en(function(e, n) e.clipboard:copy(n) end)
  api.fs.copy.relative_path                    = en(function(e, n) e.clipboard:copy_path(n) end)
  api.fs.create                                = _n(function(n) actions().fs.create_file.fn(n) end)
  api.fs.cut                                   = en(function(e, n) e.clipboard:cut(n) end)
  api.fs.paste                                 = en(function(e, n) e.clipboard:paste(n) end)
  api.fs.print_clipboard                       = e_(function(e) e.clipboard:print_clipboard() end)
  api.fs.remove                                = _n(function(n) actions().fs.remove_file.fn(n) end)
  api.fs.rename                                = _n(function(n) actions().fs.rename_file.rename_node(n) end)
  api.fs.rename_basename                       = _n(function(n) actions().fs.rename_file.rename_basename(n) end)
  api.fs.rename_full                           = _n(function(n) actions().fs.rename_file.rename_full(n) end)
  api.fs.rename_node                           = _n(function(n) actions().fs.rename_file.rename_node(n) end)
  api.fs.rename_sub                            = _n(function(n) actions().fs.rename_file.rename_sub(n) end)
  api.fs.trash                                 = _n(function(n) actions().fs.trash.fn(n) end)

  api.map.keymap.current                       = __(function() return keymap().get_keymap() end)

  api.marks.bulk.delete                        = e_(function(e) e.marks:bulk_delete() end)
  api.marks.bulk.move                          = e_(function(e) e.marks:bulk_move() end)
  api.marks.bulk.trash                         = e_(function(e) e.marks:bulk_trash() end)
  api.marks.clear                              = e_(function(e) e.marks:clear() end)
  api.marks.get                                = en(function(e, n) return e.marks:get(n) end)
  api.marks.list                               = e_(function(e) return e.marks:list() end)
  api.marks.navigate.next                      = e_(function(e) e.marks:navigate_next() end)
  api.marks.navigate.prev                      = e_(function(e) e.marks:navigate_prev() end)
  api.marks.navigate.select                    = e_(function(e) e.marks:navigate_select() end)
  api.marks.toggle                             = en(function(e, n) e.marks:toggle(n) end)

  api.node.buffer.delete                       = _n(function(n, opts) actions().node.buffer.delete(n, opts) end)
  api.node.buffer.wipe                         = _n(function(n, opts) actions().node.buffer.wipe(n, opts) end)
  api.node.collapse                            = _n(function(n) actions().tree.collapse.node(n) end)
  api.node.expand                              = en(function(e, n) e:expand_node(n) end)
  api.node.navigate.diagnostics.next           = __(function() actions().moves.item.diagnostics_next() end)
  api.node.navigate.diagnostics.next_recursive = __(function() actions().moves.item.diagnostics_next_recursive() end)
  api.node.navigate.diagnostics.prev           = __(function() actions().moves.item.diagnostics_prev() end)
  api.node.navigate.diagnostics.prev_recursive = __(function() actions().moves.item.diagnostics_prev_recursive() end)
  api.node.navigate.git.next                   = __(function() actions().moves.item.git_next() end)
  api.node.navigate.git.next_recursive         = __(function() actions().moves.item.git_next_recursive() end)
  api.node.navigate.git.next_skip_gitignored   = __(function() actions().moves.item.git_next_skip_gitignored() end)
  api.node.navigate.git.prev                   = __(function() actions().moves.item.git_prev() end)
  api.node.navigate.git.prev_recursive         = __(function() actions().moves.item.git_prev_recursive() end)
  api.node.navigate.git.prev_skip_gitignored   = __(function() actions().moves.item.git_prev_skip_gitignored() end)
  api.node.navigate.opened.next                = __(function() actions().moves.item.opened_next() end)
  api.node.navigate.opened.prev                = __(function() actions().moves.item.opened_prev() end)
  api.node.navigate.parent                     = _n(function(n) actions().moves.parent.move(n) end)
  api.node.navigate.parent_close               = _n(function(n) actions().moves.parent.move_close(n) end)
  api.node.navigate.sibling.first              = _n(function(n) actions().moves.sibling.first(n) end)
  api.node.navigate.sibling.last               = _n(function(n) actions().moves.sibling.last(n) end)
  api.node.navigate.sibling.next               = _n(function(n) actions().moves.sibling.next(n) end)
  api.node.navigate.sibling.prev               = _n(function(n) actions().moves.sibling.prev(n) end)
  api.node.open.drop                           = _n(function(n) actions().node.open_file.drop(n) end)
  api.node.open.edit                           = _n(function(n) actions().node.open_file.edit(n) end)
  api.node.open.horizontal                     = _n(function(n) actions().node.open_file.horizontal(n) end)
  api.node.open.horizontal_no_picker           = _n(function(n) actions().node.open_file.horizontal_no_picker(n) end)
  api.node.open.no_window_picker               = _n(function(n) actions().node.open_file.no_window_picker(n) end)
  api.node.open.preview                        = _n(function(n) actions().node.open_file.preview(n) end)
  api.node.open.preview_no_picker              = _n(function(n) actions().node.open_file.preview_no_picker(n) end)
  api.node.open.replace_tree_buffer            = _n(function(n) actions().node.open_file.replace_tree_buffer(n) end)
  api.node.open.tab                            = _n(function(n) actions().node.open_file.tab(n) end)
  api.node.open.tab_drop                       = _n(function(n) actions().node.open_file.tab_drop(n) end)
  api.node.open.toggle_group_empty             = _n(function(n) actions().node.open_file.toggle_group_empty(n) end)
  api.node.open.vertical                       = _n(function(n) actions().node.open_file.vertical(n) end)
  api.node.open.vertical_no_picker             = _n(function(n) actions().node.open_file.vertical_no_picker(n) end)
  api.node.run.cmd                             = _n(function(n) actions().node.run_command.run_file_command(n) end)
  api.node.run.system                          = _n(function(n) actions().node.system_open.fn(n) end)
  api.node.show_info_popup                     = _n(function(n) actions().node.file_popup.toggle_file_info(n) end)

  api.tree.change_root                         = __(function(path) actions().tree.change_dir.fn(path) end)
  api.tree.change_root_to_node                 = en(function(e, n) e:change_dir_to_node(n) end)
  api.tree.change_root_to_parent               = en(function(e, n) e:dir_up(n) end)
  api.tree.close                               = __(function() view().close() end)
  api.tree.close_in_all_tabs                   = __(function() view().close_all_tabs() end)
  api.tree.close_in_this_tab                   = __(function() view().close_this_tab_only() end)
  api.tree.collapse_all                        = __(function() actions().tree.collapse.all() end)
  api.tree.expand_all                          = en(function(e, n, opts) e:expand_all(n, opts) end)
  api.tree.find_file                           = __(function() actions().tree.find_file.fn() end)
  api.tree.focus                               = __(function() actions().tree.open.fn() end)
  api.tree.get_node_under_cursor               = en(function(e) return e:get_node_at_cursor() end)
  api.tree.get_nodes                           = en(function(e) return e:get_nodes() end)
  api.tree.is_tree_buf                         = __(function() return utils().is_nvim_tree_buf() end)
  api.tree.is_visible                          = __(function() return view().is_visible() end)
  api.tree.open                                = __(function() actions().tree.open.fn() end)
  api.tree.reload                              = e_(function(e) e:reload_explorer() end)
  api.tree.reload_git                          = e_(function(e) e:reload_git() end)
  api.tree.resize                              = __(function() actions().tree.resize.fn() end)
  api.tree.search_node                         = __(function() actions().finders.search_node.fn() end)
  api.tree.toggle                              = __(function() actions().tree.toggle.fn() end)
  api.tree.toggle_help                         = __(function() help().toggle() end)
  api.tree.winid                               = __(function() return view().winid() end)

  -- (Re)hydrate any legacy by mapping to concrete set above
  legacy.map_api(api)
end

return M
