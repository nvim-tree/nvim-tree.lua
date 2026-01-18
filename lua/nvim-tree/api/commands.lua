---@meta
local nvim_tree = { api = { commands = {} } }

---
---Arguments for [nvim_create_user_command()]
---
---@class nvim_tree.api.commands.Command
---
---@field name string
---@field command fun(args: vim.api.keyset.create_user_command.command_args)
---@field opts vim.api.keyset.user_command

---
---Retrieve all nvim-tree commands, see [nvim-tree-commands]
---
---@return nvim_tree.api.commands.Command[]
function nvim_tree.api.commands.get() end

require("nvim-tree.api").hydrate_commands(nvim_tree.api.commands)

return nvim_tree.api.commands
