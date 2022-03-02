local M = {}

function M.run_file_command(node)
  vim.api.nvim_input(": " .. node.absolute_path .. "<Home>")
end

return M

