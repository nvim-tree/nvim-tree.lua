local utils = require"nvim-tree.utils"

local M = {}

function M.fn(node)
  -- determine directory of node
  local path = node.absolute_path
  if not node.nodes then
    path = string.sub(path, 1, string.len(path) - string.len(node.name) - 1)
  end

  -- ask for command
  local shell_command = vim.fn.input("Command: ", "", "shellcmd")
  utils.clear_prompt()

  if type(shell_command) ~= 'string' or string.len(shell_command) == 0 then
    print("Invalid command")
    return
  end

  -- print which path and command
  print("Path: " .. path .. "\n")
  print("Command: " .. shell_command .. "\n\n\n")

  -- run command
  local file = io.popen("cd " .. path .. " && " .. shell_command)
  file:flush()
  local output = file:read("*all")
  file:close()

  -- print output
  print(output)
end

return M

