local M = {}

function M.path_to_matching_str(path)
  return path:gsub('(%-)', '%%-')
end

return M
