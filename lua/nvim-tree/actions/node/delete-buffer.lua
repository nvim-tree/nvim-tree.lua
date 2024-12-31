-- Copyright 2019 Yazdani Kiyan under MIT License
local utils = require("nvim-tree.actions.node.utils")

local M = {}

---@param filename string
---@param opts ApiNodeDeleteWipeBufferOpts|nil
---@return nil
function M.fn(filename, opts)
  utils.delete_buffer("delete", filename, opts)
end

function M.setup(_)
end

return M
