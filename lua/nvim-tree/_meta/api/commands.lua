---@meta
local nvim_tree = { api = { commands = {} } }

---
---@class nvim_tree.api.commands.Command
---@inlinedoc
---
---@field name string name of the `:NvimTree*` command
---@field command fun(args: vim.api.keyset.create_user_command.command_args) function that the command will execute
---@field opts vim.api.keyset.user_command [command-attributes]

---
---Retrieve all [nvim-tree-commands]
---
---They have been created via [nvim_create_user_command()], see also [lua-guide-commands-create]
---
---@return nvim_tree.api.commands.Command[]
function nvim_tree.api.commands.get() end

return nvim_tree.api.commands
