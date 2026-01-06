---@meta
error("Cannot require a meta file")

---@class nvim_tree.Config.UI
---
---|nvim_tree.Config.UI.Confirm|
---@field confirm? nvim_tree.Config.UI.Confirm

--
-- UI.Confirm
--

---Confirmation prompts.
---@class nvim_tree.Config.UI.Confirm
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
