local Api = require "nvim-tree.api"

local M = {}

local DEFAULT_KEYMAPS = {
  {
    key = { "<CR>", "o", "<2-LeftMouse>" },
    callback = Api.node.open.edit,
    desc = "open a file or folder; root will cd to the above directory",
  },
  {
    key = "<C-e>",
    callback = Api.node.open.replace_tree_buffer,
    desc = "edit the file in place, effectively replacing the tree explorer",
  },
  {
    key = "O",
    callback = Api.node.open.no_window_picker,
    desc = "same as (edit) with no window picker",
  },
  {
    key = { "<C-]>", "<2-RightMouse>" },
    callback = Api.tree.change_root_to_node,
    desc = "cd in the directory under the cursor",
  },
  {
    key = "<C-v>",
    callback = Api.node.open.vertical,
    desc = "open the file in a vertical split",
  },
  {
    key = "<C-x>",
    callback = Api.node.open.horizontal,
    desc = "open the file in a horizontal split",
  },
  {
    key = "<C-t>",
    callback = Api.node.open.tab,
    desc = "open the file in a new tab",
  },
  {
    key = "<",
    callback = Api.node.navigate.sibling.prev,
    desc = "navigate to the previous sibling of current file/directory",
  },
  {
    key = ">",
    callback = Api.node.navigate.sibling.next,
    desc = "navigate to the next sibling of current file/directory",
  },
  {
    key = "P",
    callback = Api.node.navigate.parent,
    desc = "move cursor to the parent directory",
  },
  {
    key = "<BS>",
    callback = Api.node.navigate.parent_close,
    desc = "close current opened directory or parent",
  },
  {
    key = "<Tab>",
    callback = Api.node.open.preview,
    desc = "open the file as a preview (keeps the cursor in the tree)",
  },
  {
    key = "K",
    callback = Api.node.navigate.sibling.first,
    desc = "navigate to the first sibling of current file/directory",
  },
  {
    key = "J",
    callback = Api.node.navigate.sibling.last,
    desc = "navigate to the last sibling of current file/directory",
  },
  {
    key = "I",
    callback = Api.tree.toggle_gitignore_filter,
    desc = "toggle visibility of files/folders hidden via |git.ignore| option",
  },
  {
    key = "H",
    callback = Api.tree.toggle_hidden_filter,
    desc = "toggle visibility of dotfiles via |filters.dotfiles| option",
  },
  {
    key = "U",
    callback = Api.tree.toggle_custom_filter,
    desc = "toggle visibility of files/folders hidden via |filters.custom| option",
  },
  {
    key = "R",
    callback = Api.tree.reload,
    desc = "refresh the tree",
  },
  {
    key = "a",
    callback = Api.fs.create,
    desc = "add a file; leaving a trailing `/` will add a directory",
  },
  {
    key = "d",
    callback = Api.fs.remove,
    desc = "delete a file (will prompt for confirmation)",
  },
  {
    key = "D",
    callback = Api.fs.trash,
    desc = "trash a file via |trash| option",
  },
  {
    key = "r",
    callback = Api.fs.rename,
    desc = "rename a file",
  },
  {
    key = "<C-r>",
    callback = Api.fs.rename_sub,
    desc = "rename a file and omit the filename on input",
  },
  {
    key = "x",
    callback = Api.fs.cut,
    desc = "add/remove file/directory to cut clipboard",
  },
  {
    key = "c",
    callback = Api.fs.copy.node,
    desc = "add/remove file/directory to copy clipboard",
  },
  {
    key = "p",
    callback = Api.fs.paste,
    desc = "paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation",
  },
  {
    key = "y",
    callback = Api.fs.copy.filename,
    desc = "copy name to system clipboard",
  },
  {
    key = "Y",
    callback = Api.fs.copy.relative_path,
    desc = "copy relative path to system clipboard",
  },
  {
    key = "gy",
    callback = Api.fs.copy.absolute_path,
    desc = "copy absolute path to system clipboard",
  },
  {
    key = "]e",
    callback = Api.node.navigate.diagnostics.next,
    desc = "go to next diagnostic item",
  },
  {
    key = "]c",
    callback = Api.node.navigate.git.next,
    desc = "go to next git item",
  },
  {
    key = "[e",
    callback = Api.node.navigate.diagnostics.prev,
    desc = "go to prev diagnostic item",
  },
  {
    key = "[c",
    callback = Api.node.navigate.git.prev,
    desc = "go to prev git item",
  },
  {
    key = "-",
    callback = Api.tree.change_root_to_parent,
    desc = "navigate up to the parent directory of the current file/directory",
  },
  {
    key = "s",
    callback = Api.node.run.system,
    desc = "open a file with default system application or a folder with default file manager, using |system_open| option",
  },
  {
    key = "f",
    callback = Api.live_filter.start,
    desc = "live filter nodes dynamically based on regex matching.",
  },
  {
    key = "F",
    callback = Api.live_filter.clear,
    desc = "clear live filter",
  },
  {
    key = "q",
    callback = Api.tree.close,
    desc = "close tree window",
  },
  {
    key = "W",
    callback = Api.tree.collapse_all,
    desc = "collapse the whole tree",
  },
  {
    key = "E",
    callback = Api.tree.expand_all,
    desc = "expand the whole tree, stopping after expanding |callbacks.expand_all.max_folder_discovery| folders; this might hang neovim for a while if running on a big folder",
  },
  {
    key = "S",
    callback = Api.tree.search_node,
    desc = "prompt the user to enter a path and then expands the tree to match the path",
  },
  {
    key = ".",
    callback = Api.node.run.cmd,
    desc = "enter vim command mode with the file the cursor is on",
  },
  {
    key = "<C-k>",
    callback = Api.node.show_info_popup,
    desc = "toggle a popup with file infos about the file under the cursor",
  },
  {
    key = "g?",
    callback = Api.tree.toggle_help,
    desc = "toggle help",
  },
  {
    key = "m",
    callback = Api.marks.toggle,
    desc = "Toggle node in bookmarks",
  },
  {
    key = "bmv",
    callback = Api.marks.bulk.move,
    desc = "Move all bookmarked nodes into specified location",
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

return M
