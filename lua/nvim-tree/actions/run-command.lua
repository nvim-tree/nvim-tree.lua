local M = {}

function M.run_file_command(node)
  vim.api.nvim_input(": " .. node.absolute_path .. "<Home>")
end

function M.run_directory_command(node)
  local path = node.absolute_path
  if not node.nodes then
    path = string.sub(path, 1, string.len(path) - string.len(node.name) - 1)
  end

  vim.api.nvim_input(": " .. path .. "<Home>")
end

return M

