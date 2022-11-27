local Api = require "nvim-tree.api"

local M = {}

-- BEGIN_DEFAULT_KEYMAPS
local DEFAULT_KEYMAPS = {
  {
    key = { "<CR>", "o", "<2-LeftMouse>" },
    callback = Api.node.open.edit,
    desc = {
      long = "Open a file or directory; root will cd to the above directory.",
      short = "Open",
    },
    legacy_action = "edit",
  },
  {
    key = "<C-e>",
    callback = Api.node.open.replace_tree_buffer,
    desc = {
      long = "Open file in place, effectively replacing the tree explorer.",
      short = "Open: In Place",
    },
    legacy_action = "edit_in_place",
  },
  {
    key = "O",
    callback = Api.node.open.no_window_picker,
    desc = {
      long = "Open file with no window picker.",
      short = "Open: No Window Picker",
    },
    legacy_action = "edit_no_picker",
  },
  {
    key = { "<C-]>", "<2-RightMouse>" },
    callback = Api.tree.change_root_to_node,
    desc = {
      long = "cd in the directory under the cursor.",
      short = "CD",
    },
    legacy_action = "cd",
  },
  {
    key = "<C-v>",
    callback = Api.node.open.vertical,
    desc = {
      long = "Open file in a vertical split.",
      short = "Open: Vertical Split",
    },
    legacy_action = "vsplit",
  },
  {
    key = "<C-x>",
    callback = Api.node.open.horizontal,
    desc = {
      long = "Open file in a horizontal split.",
      short = "Open: Horizontal Split",
    },
    legacy_action = "split",
  },
  {
    key = "<C-t>",
    callback = Api.node.open.tab,
    desc = {
      long = "Open file in a new tab.",
      short = "Open: New Tab",
    },
    legacy_action = "tabnew",
  },
  {
    key = "<",
    callback = Api.node.navigate.sibling.prev,
    desc = {
      long = "Navigate to the previous sibling.",
      short = "Previous Sibling",
    },
    legacy_action = "prev_sibling",
  },
  {
    key = ">",
    callback = Api.node.navigate.sibling.next,
    desc = {
      long = "Navigate to the next sibling",
      short = "Next Sibling",
    },
    legacy_action = "next_sibling",
  },
  {
    key = "P",
    callback = Api.node.navigate.parent,
    desc = {
      long = "Move cursor to the parent directory.",
      short = "Parent Directory",
    },
    legacy_action = "parent_node",
  },
  {
    key = "<BS>",
    callback = Api.node.navigate.parent_close,
    desc = {
      long = "Close current opened directory or parent.",
      short = "Close Directory",
    },
    legacy_action = "close_node",
  },
  {
    key = "<Tab>",
    callback = Api.node.open.preview,
    desc = {
      long = "Open file as a preview (keeps the cursor in the tree).",
      short = "Open Preview",
    },
    legacy_action = "preview",
  },
  {
    key = "K",
    callback = Api.node.navigate.sibling.first,
    desc = {
      long = "Navigate to the first sibling.",
      short = "First Sibling",
    },
    legacy_action = "first_sibling",
  },
  {
    key = "J",
    callback = Api.node.navigate.sibling.last,
    desc = {
      long = "Navigate to the last sibling.",
      short = "Last Sibling",
    },
    legacy_action = "last_sibling",
  },
  {
    key = "I",
    callback = Api.tree.toggle_gitignore_filter,
    desc = {
      long = "Toggle visibility of files/directories hidden via |git.ignore| option.",
      short = "Toggle Git Ignore",
    },
    legacy_action = "toggle_git_ignored",
  },
  {
    key = "H",
    callback = Api.tree.toggle_hidden_filter,
    desc = {
      long = "Toggle visibility of dotfiles via |filters.dotfiles| option.",
      short = "Toggle Dotfiles",
    },
    legacy_action = "toggle_dotfiles",
  },
  {
    key = "U",
    callback = Api.tree.toggle_custom_filter,
    desc = {
      long = "Toggle visibility of files/directories hidden via |filters.custom| option.",
      short = "Toggle Hidden",
    },
    legacy_action = "toggle_custom",
  },
  {
    key = "R",
    callback = Api.tree.reload,
    desc = {
      long = "Refresh the tree.",
      short = "Refresh",
    },
    legacy_action = "refresh",
  },
  {
    key = "a",
    callback = Api.fs.create,
    desc = {
      long = "Create a file; leaving a trailing `/` will add a directory.",
      short = "Create",
    },
    legacy_action = "create",
  },
  {
    key = "d",
    callback = Api.fs.remove,
    desc = {
      long = "Delete a file, prompting for confirmation.",
      short = "Delete",
    },
    legacy_action = "remove",
  },
  {
    key = "D",
    callback = Api.fs.trash,
    desc = {
      long = "Trash a file via |trash| option.",
      short = "Trash",
    },
    legacy_action = "trash",
  },
  {
    key = "r",
    callback = Api.fs.rename,
    desc = {
      long = "Rename a file or directory.",
      short = "Rename",
    },
    legacy_action = "rename",
  },
  {
    key = "<C-r>",
    callback = Api.fs.rename_sub,
    desc = {
      long = "Rename a file or directory and omit the filename on input.",
      short = "Rename: Omit Filename",
    },
    legacy_action = "full_rename",
  },
  {
    key = "x",
    callback = Api.fs.cut,
    desc = {
      long = "Cut file or directory to cut clipboard.",
      short = "Cut",
    },
    legacy_action = "cut",
  },
  {
    key = "c",
    callback = Api.fs.copy.node,
    desc = {
      long = "Copy file or directory to copy clipboard.",
      short = "Copy",
    },
    legacy_action = "copy",
  },
  {
    key = "p",
    callback = Api.fs.paste,
    desc = {
      long = "Paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation.",
      short = "Paste",
    },
    legacy_action = "paste",
  },
  {
    key = "y",
    callback = Api.fs.copy.filename,
    desc = {
      long = "Copy name to system clipboard.",
      short = "Copy Name",
    },
    legacy_action = "copy_name",
  },
  {
    key = "Y",
    callback = Api.fs.copy.relative_path,
    desc = {
      long = "Copy relative path to system clipboard.",
      short = "Copy Relative Path",
    },
    legacy_action = "copy_path",
  },
  {
    key = "gy",
    callback = Api.fs.copy.absolute_path,
    desc = {
      long = "Copy absolute path to system clipboard.",
      short = "Copy Absolute Path",
    },
    legacy_action = "copy_absolute_path",
  },
  {
    key = "]e",
    callback = Api.node.navigate.diagnostics.next,
    desc = {
      long = "Go to next diagnostic item.",
      short = "Next Diagnostic",
    },
    legacy_action = "next_diag_item",
  },
  {
    key = "]c",
    callback = Api.node.navigate.git.next,
    desc = {
      long = "Go to next git item.",
      short = "Next Git",
    },
    legacy_action = "next_git_item",
  },
  {
    key = "[e",
    callback = Api.node.navigate.diagnostics.prev,
    desc = {
      long = "Go to prev diagnostic item.",
      short = "Prev Diagnostic",
    },
    legacy_action = "prev_diag_item",
  },
  {
    key = "[c",
    callback = Api.node.navigate.git.prev,
    desc = {
      long = "Go to prev git item.",
      short = "Prev Git",
    },
    legacy_action = "prev_git_item",
  },
  {
    key = "-",
    callback = Api.tree.change_root_to_parent,
    desc = {
      long = "Navigate up to the parent directory of the current file/directory.",
      short = "Up",
    },
    legacy_action = "dir_up",
  },
  {
    key = "s",
    callback = Api.node.run.system,
    desc = {
      long = "Open a file with default system application or a directory with default file manager, using |system_open| option.",
      short = "Run System",
    },
    legacy_action = "system_open",
  },
  {
    key = "f",
    callback = Api.live_filter.start,
    desc = {
      long = "Live filter nodes dynamically based on regex matching.",
      short = "Filter",
    },
    legacy_action = "live_filter",
  },
  {
    key = "F",
    callback = Api.live_filter.clear,
    desc = {
      long = "Clear live filter.",
      short = "Clean Filter",
    },
    legacy_action = "clear_live_filter",
  },
  {
    key = "q",
    callback = Api.tree.close,
    desc = {
      long = "Close tree window.",
      short = "Close",
    },
    legacy_action = "close",
  },
  {
    key = "W",
    callback = Api.tree.collapse_all,
    desc = {
      long = "Collapse the whole tree.",
      short = "Collapse",
    },
    legacy_action = "collapse_all",
  },
  {
    key = "E",
    callback = Api.tree.expand_all,
    desc = {
      long = "Expand the whole tree, stopping after expanding |callbacks.expand_all.max_folder_discovery| directories; this might hang neovim for a while if running on a big directory.",
      short = "Expand All",
    },
    legacy_action = "expand_all",
  },
  {
    key = "S",
    callback = Api.tree.search_node,
    desc = {
      long = "Prompt the user to enter a path and then expands the tree to match the path.",
      short = "Search",
    },
    legacy_action = "search_node",
  },
  {
    key = ".",
    callback = Api.node.run.cmd,
    desc = {
      long = "Enter vim command mode with the file the cursor is on.",
      short = "Run Command",
    },
    legacy_action = "run_file_command",
  },
  {
    key = "<C-k>",
    callback = Api.node.show_info_popup,
    desc = {
      long = "Toggle a popup with file info about the file under the cursor.",
      short = "Info",
    },
    legacy_action = "toggle_file_info",
  },
  {
    key = "g?",
    callback = Api.tree.toggle_help,
    desc = {
      long = "Toggle help.",
      short = "Help",
    },
    legacy_action = "toggle_help",
  },
  {
    key = "m",
    callback = Api.marks.toggle,
    desc = {
      long = "Toggle node in bookmarks.",
      short = "Toggle Bookmark",
    },
    legacy_action = "toggle_mark",
  },
  {
    key = "bmv",
    callback = Api.marks.bulk.move,
    desc = {
      long = "Move all bookmarked nodes into specified location.",
      short = "Move Bookmarked",
    },
    legacy_action = "bulk_move",
  },
}
-- END_DEFAULT_KEYMAPS

function M.apply_keymaps(bufnr)
  local opts = { noremap = true, silent = true, nowait = true, buffer = bufnr }

  -- Maybe map all DEFAULT_KEYMAPS
  if M.apply_defaults then
    for _, km in ipairs(M.DEFAULT_KEYMAPS) do
      local keys = type(km.key) == "table" and km.key or { km.key }
      for _, key in ipairs(keys) do
        opts.desc = km.desc.short
        vim.keymap.set("n", key, km.callback, opts)
      end
    end
  end

  -- Maybe remove_keys
  -- We must remove after mapping instead of filtering the defaults as there are many ways to specify a key
  -- e.g. <c-k> <C-K>, <TaB> <tab>
  if M.remove_keys then
    opts.desc = nil
    for _, key in ipairs(M.remove_keys) do
      -- Delete may only be called for mappings that exist, hence we must create a dummy mapping first.
      vim.keymap.set("n", key, "", opts)
      vim.keymap.del("n", key, opts)
    end
  end

  -- Maybe apply user mappings, including legacy view.mappings.list
  if type(M.on_attach) == "function" then
    M.on_attach(bufnr)
  end
end

function M.setup(opts)
  M.on_attach = opts.on_attach
  M.apply_defaults = opts.remove_keymaps ~= true

  if type(opts.remove_keymaps) == "table" then
    M.remove_keys = opts.remove_keymaps
  end
end

M.DEFAULT_KEYMAPS = DEFAULT_KEYMAPS

return M
