local view = require'nvim-tree.view'
local M = {}

function M.compute_lines()
  local help_lines = {'HELP'}
  local help_hl = {{'NvimTreeRootFolder', 0, 0, #help_lines[1]}}
  local mappings = vim.tbl_filter(function(v)
    return v.cb ~= nil and v.cb ~= ""
  end, view.View.mappings)
  local processed = {}
  for _, b in pairs(mappings) do
    local cb = b.cb
    local key = b.key
    local name
    if cb:sub(1,35) == view.nvim_tree_callback('test'):sub(1,35) then
      name = cb:match("'[^']+'[^']*$")
      name = name:match("'[^']+'")
      table.insert(processed, {key, name, true})
    else
      name = (b.name ~= nil) and b.name or cb
      name = '"' .. name .. '"'
      table.insert(processed, {key, name, false})
    end
  end
  table.sort(processed, function(a,b)
    return (a[3] == b[3]
      and (a[2] < b[2] or (a[2] == b[2] and #a[1] < #b[1])))
      or (a[3] and not b[3])
  end)

  local num = 0
  for _, val in pairs(processed) do
    local keys = type(val[1]) == "string" and {val[1]} or val[1]
    local map_name = val[2]
    local builtin = val[3]
    for _, key in pairs(keys) do
      num = num + 1
      local bind_string = string.format("%6s : %s", key, map_name)
      table.insert(help_lines, bind_string)

      local hl_len = math.max(6, string.len(key)) + 2
      table.insert(help_hl, {'NvimTreeFolderName', num, 0, hl_len})

      if not builtin then
        table.insert(help_hl, {'NvimTreeFileRenamed', num, hl_len, -1})
      end
    end
  end
  return help_lines, help_hl
end

return M
