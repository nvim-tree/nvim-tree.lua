local M = {}

local function data_to_record(statuses)
  local uri_to_status = {}
  for _, s in pairs(statuses) do
    uri_to_status[s.path] = s.status
  end
  return uri_to_status
end

local function stripped_paths_to_record(statuses, cwd)
  local uris = {}
  for _, s in pairs(statuses) do
    if s.status ~= '!!' then
      local modified = vim.fn.fnamemodify(s.path, ':h')
      uris[modified] = true
    end
  end

  for uri, _ in pairs(uris) do
    local modified = uri
    while modified ~= cwd and modified ~= '/' do
      modified = vim.fn.fnamemodify(modified, ':h')
      uris[modified] = true
    end
  end

  return uris
end

local function iter_apply_status(nodes, uri_to_status, stripped_paths)
  for _, node in pairs(nodes) do
    if node.entries then
      node.git_status = stripped_paths[node.absolute_path] and 'dirty' or nil
      iter_apply_status(node.entries, uri_to_status, stripped_paths)
    else
      local status = uri_to_status[node.absolute_path]
      node.git_status = status
    end
  end
end

local function ignore_nodes(parent, statuses)
  for idx, node in pairs(parent.entries) do
    if statuses[node.absolute_path] == '!!' then
      parent.entries[idx] = nil
    end
  end
end

function M.update(db, parent, ignore)
  local data = db:get_from_path(parent.absolute_path)

  local uri_to_status = data_to_record(data)
  if ignore then
    ignore_nodes(parent, uri_to_status)
  end
  local stripped_paths = stripped_paths_to_record(data, parent.absolute_path)
  iter_apply_status(parent.entries, uri_to_status, stripped_paths)
end

return M
