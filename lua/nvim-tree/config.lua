-- INFO: DEPRECATED FILE, DO NOT ADD ANYTHING IN THERE
-- keeping to avoid breaking user configs. Will remove during a weekend.
local M = {}

-- TODO: remove this once the cb property is not supported in mappings, following view.mapping.list removal
function M.nvim_tree_callback(callback_name)
  -- generate_on_attach_.* will map this as per mappings.list..action
  return callback_name
end

return M
