local Api = require "nvim-tree.api"

local M = {}

M.DEFAULT_KEYMAPS = {
  {
    key = { "<CR>", "o", "<2-LeftMouse>" },
    callback = Api.node.open.edit,
    desc = {
      long = "open a file or folder; root will cd to the above directory",
      short = "Open",
    },
  },
  {
    key = "<C-e>",
    callback = Api.node.open.replace_tree_buffer,
    desc = {
      long = "edit the file in place, effectively replacing the tree explorer",
      short = "Open: In Place",
    },
  },
  {
    key = "O",
    callback = Api.node.open.no_window_picker,
    desc = {
      long = "same as (edit) with no window picker",
      short = "Open: No Window Picker",
    },
  },
  {
    key = { "<C-]>", "<2-RightMouse>" },
    callback = Api.tree.change_root_to_node,
    desc = {
      long = "cd in the directory under the cursor",
      short = "cd",
    },
  },
  {
    key = "<C-v>",
    callback = Api.node.open.vertical,
    desc = {
      long = "open the file in a vertical split",
      short = "Open: Vertical Split",
    },
  },
  {
    key = "<C-x>",
    callback = Api.node.open.horizontal,
    desc = {
      long = "open the file in a horizontal split",
      short = "Open: Horizontal Split",
    },
  },
  {
    key = "<C-t>",
    callback = Api.node.open.tab,
    desc = {
      long = "open the file in a new tab",
      short = "Open: New Tab",
    },
  },
  {
    key = "<",
    callback = Api.node.navigate.sibling.prev,
    desc = {
      long = "navigate to the previous sibling of current file/directory",
      short = "Previous Sibling",
    },
  },
  {
    key = ">",
    callback = Api.node.navigate.sibling.next,
    desc = {
      long = "navigate to the next sibling of current file/directory",
      short = "Next Sibling",
    },
  },
  {
    key = "P",
    callback = Api.node.navigate.parent,
    desc = {
      long = "move cursor to the parent directory",
      short = "Parent Directory",
    },
  },
  {
    key = "<BS>",
    callback = Api.node.navigate.parent_close,
    desc = {
      long = "close current opened directory or parent",
      short = "Close Folder",
    },
  },
  {
    key = "<Tab>",
    callback = Api.node.open.preview,
    desc = {
      long = "open the file as a preview (keeps the cursor in the tree)",
      short = "Open Preview",
    },
  },
  {
    key = "K",
    callback = Api.node.navigate.sibling.first,
    desc = {
      long = "navigate to the first sibling of current file/directory",
      short = "First Sibling",
    },
  },
  {
    key = "J",
    callback = Api.node.navigate.sibling.last,
    desc = {
      long = "navigate to the last sibling of current file/directory",
      short = "Last Sibling",
    },
  },
  {
    key = "I",
    callback = Api.tree.toggle_gitignore_filter,
    desc = {
      long = "toggle visibility of files/folders hidden via |git.ignore| option",
      short = "Toggle Git Ignore",
    },
  },
  {
    key = "H",
    callback = Api.tree.toggle_hidden_filter,
    desc = {
      long = "toggle visibility of dotfiles via |filters.dotfiles| option",
      short = "Toggle Dotfiles",
    },
  },
  {
    key = "U",
    callback = Api.tree.toggle_custom_filter,
    desc = {
      long = "toggle visibility of files/folders hidden via |filters.custom| option",
      short = "Toggle Hidden",
    },
  },
  {
    key = "R",
    callback = Api.tree.reload,
    desc = {
      long = "refresh the tree",
      short = "Refresh",
    },
  },
  {
    key = "a",
    callback = Api.fs.create,
    desc = {
      long = "add a file; leaving a trailing `/` will add a directory",
      short = "Create",
    },
  },
  {
    key = "d",
    callback = Api.fs.remove,
    desc = {
      long = "delete a file (will prompt for confirmation)",
      short = "Delete",
    },
  },
  {
    key = "D",
    callback = Api.fs.trash,
    desc = {
      long = "trash a file via |trash| option",
      short = "Trash",
    },
  },
  {
    key = "r",
    callback = Api.fs.rename,
    desc = {
      long = "rename a file",
      short = "Rename",
    },
  },
  {
    key = "<C-r>",
    callback = Api.fs.rename_sub,
    desc = {
      long = "rename a file and omit the filename on input",
      short = "Rename - Omit Filename",
    },
  },
  {
    key = "x",
    callback = Api.fs.cut,
    desc = {
      long = "add/remove file/directory to cut clipboard",
      short = "Cut",
    },
  },
  {
    key = "c",
    callback = Api.fs.copy.node,
    desc = {
      long = "add/remove file/directory to copy clipboard",
      short = "Copy",
    },
  },
  {
    key = "p",
    callback = Api.fs.paste,
    desc = {
      long = "paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation",
      short = "Paste",
    },
  },
  {
    key = "y",
    callback = Api.fs.copy.filename,
    desc = {
      long = "copy name to system clipboard",
      short = "Copy File Name",
    },
  },
  {
    key = "Y",
    callback = Api.fs.copy.relative_path,
    desc = {
      long = "copy relative path to system clipboard",
      short = "Copy Relative Path",
    },
  },
  {
    key = "gy",
    callback = Api.fs.copy.absolute_path,
    desc = {
      long = "copy absolute path to system clipboard",
      short = "Copy Absolute Path",
    },
  },
  {
    key = "[e",
    callback = Api.node.navigate.diagnostics.next,
    desc = {
      long = "go to next diagnostic item",
      short = "Next Diagnostic",
    },
  },
  {
    key = "[c",
    callback = Api.node.navigate.git.next,
    desc = {
      long = "go to next git item",
      short = "Next Git",
    },
  },
  {
    key = "]e",
    callback = Api.node.navigate.diagnostics.prev,
    desc = {
      long = "go to prev diagnostic item",
      short = "Prev Diagnostic",
    },
  },
  {
    key = "]c",
    callback = Api.node.navigate.git.prev,
    desc = {
      long = "go to prev git item",
      short = "Prev Git",
    },
  },
  {
    key = "-",
    callback = Api.tree.change_root_to_parent,
    desc = {
      long = "navigate up to the parent directory of the current file/directory",
      short = "Up",
    },
  },
  {
    key = "s",
    callback = Api.node.run.system,
    desc = {
      long = "open a file with default system application or a folder with default file manager, using |system_open| option",
      short = "Run System",
    },
  },
  {
    key = "f",
    callback = Api.live_filter.start,
    desc = {
      long = "live filter nodes dynamically based on regex matching.",
      short = "Filter",
    },
  },
  {
    key = "F",
    callback = Api.live_filter.clear,
    desc = {
      long = "clear live filter",
      short = "Clean Filter",
    },
  },
  {
    key = "q",
    callback = Api.tree.close,
    desc = {
      long = "close tree window",
      short = "Close",
    },
  },
  {
    key = "W",
    callback = Api.tree.collapse_all,
    desc = {
      long = "collapse the whole tree",
      short = "Collapse",
    },
  },
  {
    key = "E",
    callback = Api.tree.expand_all,
    desc = {
      long = "expand the whole tree, stopping after expanding |callbacks.expand_all.max_folder_discovery| folders; this might hang neovim for a while if running on a big folder",
      short = "Expand All",
    },
  },
  {
    key = "S",
    callback = Api.tree.search_node,
    desc = {
      long = "prompt the user to enter a path and then expands the tree to match the path",
      short = "Search",
    },
  },
  {
    key = ".",
    callback = Api.node.run.cmd,
    desc = {
      long = "enter vim command mode with the file the cursor is on",
      short = "Run Command",
    },
  },
  {
    key = "<C-k>",
    callback = Api.node.show_info_popup,
    desc = {
      long = "toggle a popup with file infos about the file under the cursor",
      short = "Info",
    },
  },
  {
    key = "g?",
    callback = Api.tree.toggle_help,
    desc = {
      long = "toggle help",
      short = "Help",
    },
  },
  {
    key = "m",
    callback = Api.marks.toggle,
    desc = {
      long = "Toggle node in bookmarks",
      short = "Toggle Bookmark",
    },
  },
  {
    key = "bmv",
    callback = Api.marks.bulk.move,
    desc = {
      long = "Move all bookmarked nodes into specified location",
      short = "Move Bookmarked",
    },
  },
}

function M.set_keymaps(bufnr)
  local opts = { noremap = true, silent = true, nowait = true, buffer = bufnr }
  for _, km in ipairs(M.keymaps) do
    local keys = type(km.key) == "table" and km.key or { km.key }
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, km.callback, opts)
    end
  end
end

local function filter_default_mappings(keys_to_disable)
  local new_map = {}
  for _, m in pairs(M.DEFAULT_KEYMAPS) do
    local keys = type(m.key) == "table" and m.key or { m.key }
    local reminding_keys = {}
    for _, key in pairs(keys) do
      local found = false
      for _, key_to_disable in pairs(keys_to_disable) do
        if key_to_disable == key then
          found = true
          break
        end
      end
      if not found then
        table.insert(reminding_keys, key)
      end
    end
    if #reminding_keys > 0 then
      local map = vim.deepcopy(m)
      map.key = reminding_keys
      table.insert(new_map, map)
    end
  end
  return new_map
end

local function get_keymaps(keys_to_disable)
  if keys_to_disable == true then
    return {}
  end

  if type(keys_to_disable) == "table" and #keys_to_disable > 0 then
    return filter_default_mappings(keys_to_disable)
  end

  return M.DEFAULT_KEYMAPS
end

function M.setup(opts)
  M.keymaps = get_keymaps(opts.remove_keymaps)
end

return M
