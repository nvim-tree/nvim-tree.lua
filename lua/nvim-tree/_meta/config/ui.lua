---@meta
error("Cannot require a meta file")



---@class nvim_tree.config.ui
---
---[nvim_tree.config.ui.confirm]
---@field confirm? nvim_tree.config.ui.confirm



---Confirmation prompts.
---@class nvim_tree.config.ui.confirm
---
---Prompt before removing.
---(default: `true`)
---@field remove? boolean
---
---Prompt before trashing.
---(default: `true`)
---@field trash? boolean
---
---If `true` the prompt will be `Y/n`, otherwise `y/N`
---(default: `false`)
---@field default_yes? boolean
