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
  },
  {
    key = "<C-e>",
    callback = Api.node.open.replace_tree_buffer,
    desc = {
      long = "Open file in place, effectively replacing the tree explorer.",
      short = "Open: In Place",
    },
  },
  {
    key = "O",
    callback = Api.node.open.no_window_picker,
    desc = {
      long = "Open file with no window picker.",
      short = "Open: No Window Picker",
    },
  },
  {
    key = { "<C-]>", "<2-RightMouse>" },
    callback = Api.tree.change_root_to_node,
    desc = {
      long = "cd in the directory under the cursor.",
      short = "CD",
    },
  },
  {
    -- key = "<C-v>",
    key = "<ctrL-v>",
    callback = Api.node.open.vertical,
    desc = {
      long = "Open file in a vertical split.",
      short = "Open: Vertical Split",
    },
  },
  {
    key = "<C-x>",
    callback = Api.node.open.horizontal,
    desc = {
      long = "Open file in a horizontal split.",
      short = "Open: Horizontal Split",
    },
  },
  {
    key = "<C-t>",
    callback = Api.node.open.tab,
    desc = {
      long = "Open file in a new tab.",
      short = "Open: New Tab",
    },
  },
  {
    key = "<",
    callback = Api.node.navigate.sibling.prev,
    desc = {
      long = "Navigate to the previous sibling.",
      short = "Previous Sibling",
    },
  },
  {
    key = ">",
    callback = Api.node.navigate.sibling.next,
    desc = {
      long = "Navigate to the next sibling",
      short = "Next Sibling",
    },
  },
  {
    key = "P",
    callback = Api.node.navigate.parent,
    desc = {
      long = "Move cursor to the parent directory.",
      short = "Parent Directory",
    },
  },
  {
    key = "<BS>",
    callback = Api.node.navigate.parent_close,
    desc = {
      long = "Close current opened directory or parent.",
      short = "Close Directory",
    },
  },
  {
    key = "<Tab>",
    callback = Api.node.open.preview,
    desc = {
      long = "Open file as a preview (keeps the cursor in the tree).",
      short = "Open Preview",
    },
  },
  {
    key = "K",
    callback = Api.node.navigate.sibling.first,
    desc = {
      long = "Navigate to the first sibling.",
      short = "First Sibling",
    },
  },
  {
    key = "J",
    callback = Api.node.navigate.sibling.last,
    desc = {
      long = "Navigate to the last sibling.",
      short = "Last Sibling",
    },
  },
  {
    key = "I",
    callback = Api.tree.toggle_gitignore_filter,
    desc = {
      long = "Toggle visibility of files/directories hidden via |git.ignore| option.",
      short = "Toggle Git Ignore",
    },
  },
  {
    key = "H",
    callback = Api.tree.toggle_hidden_filter,
    desc = {
      long = "Toggle visibility of dotfiles via |filters.dotfiles| option.",
      short = "Toggle Dotfiles",
    },
  },
  {
    key = "U",
    callback = Api.tree.toggle_custom_filter,
    desc = {
      long = "Toggle visibility of files/directories hidden via |filters.custom| option.",
      short = "Toggle Hidden",
    },
  },
  {
    key = "R",
    callback = Api.tree.reload,
    desc = {
      long = "Refresh the tree.",
      short = "Refresh",
    },
  },
  {
    key = "a",
    callback = Api.fs.create,
    desc = {
      long = "Create a file; leaving a trailing `/` will add a directory.",
      short = "Create",
    },
  },
  {
    key = "d",
    callback = Api.fs.remove,
    desc = {
      long = "Delete a file, prompting for confirmation.",
      short = "Delete",
    },
  },
  {
    key = "D",
    callback = Api.fs.trash,
    desc = {
      long = "Trash a file via |trash| option.",
      short = "Trash",
    },
  },
  {
    key = "r",
    callback = Api.fs.rename,
    desc = {
      long = "Rename a file or directory.",
      short = "Rename",
    },
  },
  {
    key = "<C-r>",
    callback = Api.fs.rename_sub,
    desc = {
      long = "Rename a file or directory and omit the filename on input.",
      short = "Rename: Omit Filename",
    },
  },
  {
    key = "x",
    callback = Api.fs.cut,
    desc = {
      long = "Cut file or directory to cut clipboard.",
      short = "Cut",
    },
  },
  {
    key = "c",
    callback = Api.fs.copy.node,
    desc = {
      long = "Copy file or directory to copy clipboard.",
      short = "Copy",
    },
  },
  {
    key = "p",
    callback = Api.fs.paste,
    desc = {
      long = "Paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation.",
      short = "Paste",
    },
  },
  {
    key = "y",
    callback = Api.fs.copy.filename,
    desc = {
      long = "Copy name to system clipboard.",
      short = "Copy Name",
    },
  },
  {
    key = "Y",
    callback = Api.fs.copy.relative_path,
    desc = {
      long = "Copy relative path to system clipboard.",
      short = "Copy Relative Path",
    },
  },
  {
    key = "gy",
    callback = Api.fs.copy.absolute_path,
    desc = {
      long = "Copy absolute path to system clipboard.",
      short = "Copy Absolute Path",
    },
  },
  {
    key = "]e",
    callback = Api.node.navigate.diagnostics.next,
    desc = {
      long = "Go to next diagnostic item.",
      short = "Next Diagnostic",
    },
  },
  {
    key = "]c",
    callback = Api.node.navigate.git.next,
    desc = {
      long = "Go to next git item.",
      short = "Next Git",
    },
  },
  {
    key = "[e",
    callback = Api.node.navigate.diagnostics.prev,
    desc = {
      long = "Go to prev diagnostic item.",
      short = "Prev Diagnostic",
    },
  },
  {
    key = "[c",
    callback = Api.node.navigate.git.prev,
    desc = {
      long = "Go to prev git item.",
      short = "Prev Git",
    },
  },
  {
    key = "-",
    callback = Api.tree.change_root_to_parent,
    desc = {
      long = "Navigate up to the parent directory of the current file/directory.",
      short = "Up",
    },
  },
  {
    key = "s",
    callback = Api.node.run.system,
    desc = {
      long = "Open a file with default system application or a directory with default file manager, using |system_open| option.",
      short = "Run System",
    },
  },
  {
    key = "f",
    callback = Api.live_filter.start,
    desc = {
      long = "Live filter nodes dynamically based on regex matching.",
      short = "Filter",
    },
  },
  {
    key = "F",
    callback = Api.live_filter.clear,
    desc = {
      long = "Clear live filter.",
      short = "Clean Filter",
    },
  },
  {
    key = "q",
    callback = Api.tree.close,
    desc = {
      long = "Close tree window.",
      short = "Close",
    },
  },
  {
    key = "W",
    callback = Api.tree.collapse_all,
    desc = {
      long = "Collapse the whole tree.",
      short = "Collapse",
    },
  },
  {
    key = "E",
    callback = Api.tree.expand_all,
    desc = {
      long = "Expand the whole tree, stopping after expanding |callbacks.expand_all.max_folder_discovery| directories; this might hang neovim for a while if running on a big directory.",
      short = "Expand All",
    },
  },
  {
    key = "S",
    callback = Api.tree.search_node,
    desc = {
      long = "Prompt the user to enter a path and then expands the tree to match the path.",
      short = "Search",
    },
  },
  {
    key = ".",
    callback = Api.node.run.cmd,
    desc = {
      long = "Enter vim command mode with the file the cursor is on.",
      short = "Run Command",
    },
  },
  {
    key = "<C-k>",
    callback = Api.node.show_info_popup,
    desc = {
      long = "Toggle a popup with file info about the file under the cursor.",
      short = "Info",
    },
  },
  {
    key = "g?",
    callback = Api.tree.toggle_help,
    desc = {
      long = "Toggle help.",
      short = "Help",
    },
  },
  {
    key = "m",
    callback = Api.marks.toggle,
    desc = {
      long = "Toggle node in bookmarks.",
      short = "Toggle Bookmark",
    },
  },
  {
    key = "bmv",
    callback = Api.marks.bulk.move,
    desc = {
      long = "Move all bookmarked nodes into specified location.",
      short = "Move Bookmarked",
    },
  },
}
-- END_DEFAULT_KEYMAPS

function M.set_keymaps(bufnr)
  local opts = { noremap = true, silent = true, nowait = true, buffer = bufnr }
  for _, km in ipairs(M.keymaps) do
    local keys = type(km.key) == "table" and km.key or { km.key }
    for _, key in ipairs(keys) do
      opts.desc = km.desc.short
      vim.keymap.set("n", key, km.callback, opts)
    end
  end
end

local function filter_default_mappings(keys_to_disable)
  local new_map = {}
  for _, m in pairs(DEFAULT_KEYMAPS) do
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

  return DEFAULT_KEYMAPS
end

function M.setup(opts)
  M.keymaps = get_keymaps(opts.remove_keymaps)
end

M.DEFAULT_KEYMAPS = DEFAULT_KEYMAPS

return M
