local git_table = require'nvim-tree.renderer2.git'

local M = {}

-- TODO: License icon ?
-- check default icon
function M.icon(node, _icons, with_folder_icon, with_file_icon, with_devicon)
  if node.entries then
    if not with_folder_icon then
      return { display = '', highlight = nil }
    end

    local icons = _icons.folder_icons
    local icon
    if node.open and node.has_children then
      icon = node.link_to and icons.symlink_open or icons.open
    elseif node.open and not node.has_children then
      icon = node.link_to and icons.empty_symlink_open or icons.empty_open
    elseif not node.open and not node.has_children then
      icon = node.link_to and icons.empty_symlink or icons.empty
    else
      icon = node.link_to and icons.symlink or icons.default
    end

    return {
      display = icon..' ',
      highlight = 'NvimTreeFolderIcon'
    }
  elseif node.link_to then
    if not with_file_icon or not _icons.symlink or #_icons.symlink == 0 then
      return { display = '', highlight = nil }
    end

    return { display = _icons.symlink, highlight = 'NvimTreeSymlinkIcon' }
  else
    if not with_file_icon then
      return { display = '', highlight = nil }
    end

    if with_devicon then
      local icon, highlight = require'nvim-web-devicons'.get_icon(node.extension)
      if not icon then
        return { display = _icons.default, highlight = nil }
      end

      return { display = icon..' ', highlight = highlight }
    end

    return { display = _icons.default, highlight = nil }
  end

end

-- TODO: opened file in buffers
function M.name(node, pictures, specials)
  local highlight = nil
  if node.entries then
    if node.open then
      highlight = node.link_to and 'NvimTreeOpenedSymlinkFolderName' or 'NvimTreeOpenedFolderName'
    elseif not node.has_children then
      highlight = node.link_to and 'NvimTreeEmptySymlinkFolderName' or 'NvimTreeEmptyFolderName'
    else
      highlight = node.link_to and 'NvimTreeSymlinkFolderName' or 'NvimTreeFolderName'
    end
  elseif node.link_to then
    highlight = 'NvimTreeSymlink'
  elseif node.executable then
    highlight = 'NvimTreeExecFile'
  elseif specials[node.name] or specials[node.absolute_path] then
    highlight = 'NvimTreeSpecialFile'
  elseif pictures[node.extension] then
    highlight = 'NvimTreeImageFile'
  end


  return { display = node.name, highlight = highlight }
end

function M.padding(idx, node, nodes, _depth, markers, with_arrows, with_markers, icons)
  local show_arrow = node.entries and with_arrows
  local depth = with_arrows and _depth - 2 or _depth
  if not with_markers and not show_arrow then
    return string.rep(' ', depth)
  end

  local padding = nil
  if with_markers and depth > 0 then
    padding = ""
    local rdepth = depth/2
    markers[rdepth] = idx ~= #nodes
    for i=1,rdepth do
      if idx == #nodes and i == rdepth then
        padding = padding..'└ '
      elseif markers[i] then
        padding = padding..'│ '
      else
        padding = padding..'  '
      end
    end
  end

  local icon = ""
  if show_arrow then
    icon = icons[node.open and 'arrow_open' or 'arrow_closed']..' '
  end
  if padding then
    padding = padding..icon
  else
    padding = string.rep(' ', depth)..icon
  end


  return padding
end

function M.git(node, icons)
  local values = git_table[node.git_status] or {}
  return vim.tbl_map(function(n) return { icon = icons[n.icon], highlight = n.hl } end, values)
end

return M
