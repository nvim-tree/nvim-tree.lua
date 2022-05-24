local M = {}

function M.get_config()
  local show_icons = vim.g.nvim_tree_show_icons or { git = 1, folders = 1, files = 1, folder_arrows = 1 }
  local default_icons = {
    default = "",
    symlink = "",
    git_icons = {
      unstaged = "✗",
      staged = "✓",
      unmerged = "",
      renamed = "➜",
      untracked = "★",
      deleted = "",
      ignored = "◌",
    },
    folder_icons = {
      arrow_closed = "",
      arrow_open = "",
      default = "",
      open = "",
      empty = "",
      empty_open = "",
      symlink = "",
      symlink_open = "",
    },
  }

  local user_icons = vim.g.nvim_tree_icons
  local icons = vim.tbl_deep_extend("keep", user_icons, default_icons)

  local has_devicons = pcall(require, "nvim-web-devicons")

  return {
    show_file_icon = show_icons.files == 1,
    show_folder_icon = show_icons.folders == 1,
    show_git_icon = show_icons.git == 1,
    show_folder_arrows = show_icons.folder_arrows == 1,
    has_devicons = has_devicons,
    icons = icons,
  }
end

return M
