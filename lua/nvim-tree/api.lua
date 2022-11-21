local Api = {
  tree = {},
  node = { navigate = { sibling = {}, git = {}, diagnostics = {} }, run = {}, open = {} },
  events = {},
  marks = { bulk = {}, navigate = {} },
  fs = { copy = {} },
  git = {},
  live_filter = {},
}

local function inject_node(f)
  return function(node)
    node = node or require("nvim-tree.lib").get_node_at_cursor()
    f(node)
  end
end

Api.tree.open = require("nvim-tree").open
Api.tree.toggle = require("nvim-tree").toggle
Api.tree.close = require("nvim-tree.view").close
Api.tree.close_in_this_tab = require("nvim-tree.view").close_this_tab_only
Api.tree.close_in_all_tabs = require("nvim-tree.view").close_all_tabs
Api.tree.focus = require("nvim-tree").focus
Api.tree.reload = require("nvim-tree.actions.reloaders.reloaders").reload_explorer
Api.tree.change_root = require("nvim-tree").change_dir
Api.tree.change_root_to_node = inject_node(function(node)
  if node.name == ".." then
    require("nvim-tree.actions.root.change-dir").fn ".."
  elseif node.nodes ~= nil then
    require("nvim-tree.actions.root.change-dir").fn(require("nvim-tree.lib").get_last_group_node(node).absolute_path)
  end
end)
Api.tree.change_root_to_parent = inject_node(require("nvim-tree.actions.root.dir-up").fn)
Api.tree.get_node_under_cursor = require("nvim-tree.lib").get_node_at_cursor
Api.tree.get_nodes = require("nvim-tree.lib").get_nodes
Api.tree.find_file = require("nvim-tree.actions.finders.find-file").fn
Api.tree.search_node = require("nvim-tree.actions.finders.search-node").fn
Api.tree.collapse_all = require("nvim-tree.actions.tree-modifiers.collapse-all").fn
Api.tree.expand_all = inject_node(require("nvim-tree.actions.tree-modifiers.expand-all").fn)
Api.tree.toggle_gitignore_filter = require("nvim-tree.actions.tree-modifiers.toggles").git_ignored
Api.tree.toggle_custom_filter = require("nvim-tree.actions.tree-modifiers.toggles").custom
Api.tree.toggle_hidden_filter = require("nvim-tree.actions.tree-modifiers.toggles").dotfiles
Api.tree.toggle_help = require("nvim-tree.actions.tree-modifiers.toggles").help

Api.fs.create = inject_node(require("nvim-tree.actions.fs.create-file").fn)
Api.fs.remove = inject_node(require("nvim-tree.actions.fs.remove-file").fn)
Api.fs.trash = inject_node(require("nvim-tree.actions.fs.trash").fn)
Api.fs.rename = inject_node(require("nvim-tree.actions.fs.rename-file").fn(false))
Api.fs.rename_sub = inject_node(require("nvim-tree.actions.fs.rename-file").fn(true))
Api.fs.cut = inject_node(require("nvim-tree.actions.fs.copy-paste").cut)
Api.fs.paste = inject_node(require("nvim-tree.actions.fs.copy-paste").paste)
Api.fs.clear_clipboard = require("nvim-tree.actions.fs.copy-paste").clear_clipboard
Api.fs.print_clipboard = require("nvim-tree.actions.fs.copy-paste").print_clipboard
Api.fs.copy.node = inject_node(require("nvim-tree.actions.fs.copy-paste").copy)
Api.fs.copy.absolute_path = inject_node(require("nvim-tree.actions.fs.copy-paste").copy_absolute_path)
Api.fs.copy.filename = inject_node(require("nvim-tree.actions.fs.copy-paste").copy_filename)
Api.fs.copy.relative_path = inject_node(require("nvim-tree.actions.fs.copy-paste").copy_path)

local function edit(mode, node)
  local path = node.absolute_path
  if node.link_to and not node.nodes then
    path = node.link_to
  end
  require("nvim-tree.actions.node.open-file").fn(mode, path)
end

local function open_or_expand_or_dir_up(mode)
  return function(node)
    if node.name == ".." then
      require("nvim-tree.actions.root.change-dir").fn ".."
    elseif node.nodes then
      require("nvim-tree.lib").expand_or_collapse(node)
    else
      edit(mode, node)
    end
  end
end

local function open_preview(node)
  if node.nodes or node.name == ".." then
    return
  end

  edit("preview", node)
end

Api.node.open.edit = inject_node(open_or_expand_or_dir_up "edit")
Api.node.open.replace_tree_buffer = inject_node(open_or_expand_or_dir_up "edit_in_place")
Api.node.open.no_window_picker = inject_node(open_or_expand_or_dir_up "edit_no_picker")
Api.node.open.vertical = inject_node(open_or_expand_or_dir_up "vsplit")
Api.node.open.horizontal = inject_node(open_or_expand_or_dir_up "split")
Api.node.open.tab = inject_node(open_or_expand_or_dir_up "tabnew")
Api.node.open.preview = inject_node(open_preview)

Api.node.show_info_popup = inject_node(require("nvim-tree.actions.node.file-popup").toggle_file_info)
Api.node.run.cmd = inject_node(require("nvim-tree.actions.node.run-command").run_file_command)
Api.node.run.system = inject_node(require("nvim-tree.actions.node.system-open").fn)
Api.node.navigate.sibling.next = inject_node(require("nvim-tree.actions.moves.sibling").fn "next")
Api.node.navigate.sibling.prev = inject_node(require("nvim-tree.actions.moves.sibling").fn "prev")
Api.node.navigate.sibling.first = inject_node(require("nvim-tree.actions.moves.sibling").fn "first")
Api.node.navigate.sibling.last = inject_node(require("nvim-tree.actions.moves.sibling").fn "last")
Api.node.navigate.parent = inject_node(require("nvim-tree.actions.moves.parent").fn(false))
Api.node.navigate.parent_close = inject_node(require("nvim-tree.actions.moves.parent").fn(true))
Api.node.navigate.git.next = inject_node(require("nvim-tree.actions.moves.item").fn("next", "git"))
Api.node.navigate.git.prev = inject_node(require("nvim-tree.actions.moves.item").fn("prev", "git"))
Api.node.navigate.diagnostics.next = inject_node(require("nvim-tree.actions.moves.item").fn("next", "diag"))
Api.node.navigate.diagnostics.prev = inject_node(require("nvim-tree.actions.moves.item").fn("prev", "diag"))

Api.git.reload = require("nvim-tree.actions.reloaders.reloaders").reload_git

Api.events.subscribe = require("nvim-tree.events").subscribe
Api.events.Event = require("nvim-tree.events").Event

Api.live_filter.start = require("nvim-tree.live-filter").start_filtering
Api.live_filter.clear = require("nvim-tree.live-filter").clear_filter

Api.marks.get = inject_node(require("nvim-tree.marks").get_mark)
Api.marks.list = require("nvim-tree.marks").get_marks
Api.marks.toggle = inject_node(require("nvim-tree.marks").toggle_mark)
Api.marks.clear = require("nvim-tree.marks").clear_marks
Api.marks.bulk.move = require("nvim-tree.marks.bulk-move").bulk_move
Api.marks.navigate.next = require("nvim-tree.marks.navigation").next
Api.marks.navigate.prev = require("nvim-tree.marks.navigation").prev
Api.marks.navigate.select = require("nvim-tree.marks.navigation").select

return Api
