---Hydrates all API functions with concrete implementations.
---Replace all "nvim-tree setup not called" error functions from pre.lua with their implementations.
---
---Called after nvim-tree setup

local M = {}

---Return a function wrapper that calls fn.
---Injects node or node at cursor as first argument.
---Passes other arguments verbatim.
---@param fn fun(n?: Node, ...): any
---@return fun(n?: Node, ...): any
local function _n(fn)
  return function(n, ...)
    if not n then
      local e = require("nvim-tree.core").get_explorer()
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
    local e = require("nvim-tree.core").get_explorer()
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
    local e = require("nvim-tree.core").get_explorer()
    if e then
      n = e and e:get_node_at_cursor() or nil
      return fn(e, n, ...)
    end
  end
end

local function ev(fn)
  -- TODO following rebase
end

local function _v(fn)
  -- TODO following rebase
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
  api.fs.create                                = _n(function(n) require("nvim-tree.actions").fs.create_file.fn(n) end)
  api.fs.cut                                   = ev(function(e, n) e.clipboard:cut(n) end)
  api.fs.paste                                 = en(function(e, n) e.clipboard:paste(n) end)
  api.fs.print_clipboard                       = e_(function(e) e.clipboard:print_clipboard() end)
  api.fs.remove                                = _v(function(n) require("nvim-tree.actions").fs.remove_file.fn(n) end)
  api.fs.rename                                = _n(function(n) require("nvim-tree.actions").fs.rename_file.rename_node(n) end)
  api.fs.rename_basename                       = _n(function(n) require("nvim-tree.actions").fs.rename_file.rename_basename(n) end)
  api.fs.rename_full                           = _n(function(n) require("nvim-tree.actions").fs.rename_file.rename_full(n) end)
  api.fs.rename_node                           = _n(function(n) require("nvim-tree.actions").fs.rename_file.rename_node(n) end)
  api.fs.rename_sub                            = _n(function(n) require("nvim-tree.actions").fs.rename_file.rename_sub(n) end)
  api.fs.trash                                 = _v(function(n) require("nvim-tree.actions").fs.trash.fn(n) end)

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

  api.node.buffer.delete                       = _n(function(n, opts) require("nvim-tree.actions").node.buffer.delete(n, opts) end)
  api.node.buffer.wipe                         = _n(function(n, opts) require("nvim-tree.actions").node.buffer.wipe(n, opts) end)
  api.node.collapse                            = _n(function(n) require("nvim-tree.actions").tree.collapse.node(n) end)
  api.node.expand                              = en(function(e, n) e:expand_node(n) end)
  api.node.navigate.diagnostics.next           = __(function() require("nvim-tree.actions").moves.item.diagnostics_next() end)
  api.node.navigate.diagnostics.next_recursive = __(function() require("nvim-tree.actions").moves.item.diagnostics_next_recursive() end)
  api.node.navigate.diagnostics.prev           = __(function() require("nvim-tree.actions").moves.item.diagnostics_prev() end)
  api.node.navigate.diagnostics.prev_recursive = __(function() require("nvim-tree.actions").moves.item.diagnostics_prev_recursive() end)
  api.node.navigate.git.next                   = __(function() require("nvim-tree.actions").moves.item.git_next() end)
  api.node.navigate.git.next_recursive         = __(function() require("nvim-tree.actions").moves.item.git_next_recursive() end)
  api.node.navigate.git.next_skip_gitignored   = __(function() require("nvim-tree.actions").moves.item.git_next_skip_gitignored() end)
  api.node.navigate.git.prev                   = __(function() require("nvim-tree.actions").moves.item.git_prev() end)
  api.node.navigate.git.prev_recursive         = __(function() require("nvim-tree.actions").moves.item.git_prev_recursive() end)
  api.node.navigate.git.prev_skip_gitignored   = __(function() require("nvim-tree.actions").moves.item.git_prev_skip_gitignored() end)
  api.node.navigate.opened.next                = __(function() require("nvim-tree.actions").moves.item.opened_next() end)
  api.node.navigate.opened.prev                = __(function() require("nvim-tree.actions").moves.item.opened_prev() end)
  api.node.navigate.parent                     = _n(function(n) require("nvim-tree.actions").moves.parent.move(n) end)
  api.node.navigate.parent_close               = _n(function(n) require("nvim-tree.actions").moves.parent.move_close(n) end)
  api.node.navigate.sibling.first              = _n(function(n) require("nvim-tree.actions").moves.sibling.first(n) end)
  api.node.navigate.sibling.last               = _n(function(n) require("nvim-tree.actions").moves.sibling.last(n) end)
  api.node.navigate.sibling.next               = _n(function(n) require("nvim-tree.actions").moves.sibling.next(n) end)
  api.node.navigate.sibling.prev               = _n(function(n) require("nvim-tree.actions").moves.sibling.prev(n) end)
  api.node.open.drop                           = _n(function(n) require("nvim-tree.actions").node.open_file.drop(n) end)
  api.node.open.edit                           = _n(function(n) require("nvim-tree.actions").node.open_file.edit(n) end)
  api.node.open.horizontal                     = _n(function(n) require("nvim-tree.actions").node.open_file.horizontal(n) end)
  api.node.open.horizontal_no_picker           = _n(function(n) require("nvim-tree.actions").node.open_file.horizontal_no_picker(n) end)
  api.node.open.no_window_picker               = _n(function(n) require("nvim-tree.actions").node.open_file.no_window_picker(n) end)
  api.node.open.preview                        = _n(function(n) require("nvim-tree.actions").node.open_file.preview(n) end)
  api.node.open.preview_no_picker              = _n(function(n) require("nvim-tree.actions").node.open_file.preview_no_picker(n) end)
  api.node.open.replace_tree_buffer            = _n(function(n) require("nvim-tree.actions").node.open_file.replace_tree_buffer(n) end)
  api.node.open.tab                            = _n(function(n) require("nvim-tree.actions").node.open_file.tab(n) end)
  api.node.open.tab_drop                       = _n(function(n) require("nvim-tree.actions").node.open_file.tab_drop(n) end)
  api.node.open.toggle_group_empty             = _n(function(n) require("nvim-tree.actions").node.open_file.toggle_group_empty(n) end)
  api.node.open.vertical                       = _n(function(n) require("nvim-tree.actions").node.open_file.vertical(n) end)
  api.node.open.vertical_no_picker             = _n(function(n) require("nvim-tree.actions").node.open_file.vertical_no_picker(n) end)
  api.node.run.cmd                             = _n(function(n) require("nvim-tree.actions").node.run_command.run_file_command(n) end)
  api.node.run.system                          = _n(function(n) require("nvim-tree.actions").node.system_open.fn(n) end)
  api.node.show_info_popup                     = _n(function(n) require("nvim-tree.actions").node.file_popup.toggle_file_info(n) end)

  api.tree.change_root                         = __(function(path) require("nvim-tree.actions").tree.change_dir.fn(path) end)
  api.tree.change_root_to_node                 = en(function(e, n) e:change_dir_to_node(n) end)
  api.tree.change_root_to_parent               = en(function(e, n) e:dir_up(n) end)
  api.tree.close                               = __(function() require("nvim-tree.view").close() end)
  api.tree.close_in_all_tabs                   = __(function() require("nvim-tree.view").close_all_tabs() end)
  api.tree.close_in_this_tab                   = __(function() require("nvim-tree.view").close_this_tab_only() end)
  api.tree.collapse_all                        = __(function() require("nvim-tree.actions").tree.collapse.all() end)
  api.tree.expand_all                          = en(function(e, n, opts) e:expand_all(n, opts) end)
  api.tree.find_file                           = __(function() require("nvim-tree.actions").tree.find_file.fn() end)
  api.tree.focus                               = __(function() require("nvim-tree.actions").tree.open.fn() end)
  api.tree.get_node_under_cursor               = en(function(e) return e:get_node_at_cursor() end)
  api.tree.get_nodes                           = en(function(e) return e:get_nodes() end)
  api.tree.is_tree_buf                         = __(function() return require("nvim-tree.utils").is_nvim_tree_buf() end)
  api.tree.is_visible                          = __(function() return require("nvim-tree.view").is_visible() end)
  api.tree.open                                = __(function() require("nvim-tree.actions").tree.open.fn() end)
  api.tree.reload                              = e_(function(e) e:reload_explorer() end)
  api.tree.reload_git                          = e_(function(e) e:reload_git() end)
  api.tree.resize                              = __(function() require("nvim-tree.actions").tree.resize.fn() end)
  api.tree.search_node                         = __(function() require("nvim-tree.actions").finders.search_node.fn() end)
  api.tree.toggle                              = __(function() require("nvim-tree.actions").tree.toggle.fn() end)
  api.tree.toggle_help                         = __(function() require("nvim-tree.help").toggle() end)
  api.tree.winid                               = __(function() return require("nvim-tree.view").winid() end)

  -- (Re)hydrate any legacy by mapping to concrete set above
  require("nvim-tree.legacy").map_api(api)
end

return M
