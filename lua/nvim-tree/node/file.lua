local git_utils = require("nvim-tree.git.utils")
local icons = require("nvim-tree.renderer.components.devicons")
local utils = require("nvim-tree.utils")

local Node = require("nvim-tree.node")

local PICTURE_MAP = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
  webp = true,
  jxl = true,
}

---@class (exact) FileNode: Node
---@field extension string
local FileNode = Node:new()

---Static factory method
---@param explorer Explorer
---@param parent DirectoryNode
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@return FileNode
function FileNode:create(explorer, parent, absolute_path, name, fs_stat)
  ---@type FileNode
  local o = {
    type = "file",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = utils.is_executable(absolute_path),
    fs_stat = fs_stat,
    git_status = nil,
    hidden = false,
    name = name,
    parent = parent,
    diag_status = nil,
    is_dot = false,

    extension = string.match(name, ".?[^.]+%.(.*)") or "",
  }
  o = self:new(o)

  return o
end

function FileNode:destroy()
  Node.destroy(self)
end

---Update the GitStatus of the file
---@param parent_ignored boolean
---@param project GitProject?
function FileNode:update_git_status(parent_ignored, project)
  self.git_status = git_utils.git_status_file(parent_ignored, project, self.absolute_path, nil)
end

---@return GitXY[]?
function FileNode:get_git_xy()
  if not self.git_status then
    return nil
  end

  return self.git_status.file and { self.git_status.file }
end

---@return HighlightedString icon
function FileNode:highlighted_icon()
  if not self.explorer.opts.renderer.icons.show.file then
    return self:highlighted_icon_empty()
  end

  local str, hl

  -- devicon if enabled and available, fallback to default
  if self.explorer.opts.renderer.icons.web_devicons.file.enable then
    str, hl = icons.get_icon(self.name, nil, { default = true })
    if not self.explorer.opts.renderer.icons.web_devicons.file.color then
      hl = nil
    end
  end

  -- default icon from opts
  if not str then
    str = self.explorer.opts.renderer.icons.glyphs.default
  end

  -- default hl
  if not hl then
    hl = "NvimTreeFileIcon"
  end

  return { str = str, hl = { hl } }
end

---@return HighlightedString name
function FileNode:highlighted_name()
  local hl
  if vim.tbl_contains(self.explorer.opts.renderer.special_files, self.absolute_path) or vim.tbl_contains(self.explorer.opts.renderer.special_files, self.name) then
    hl = "NvimTreeSpecialFile"
  elseif self.executable then
    hl = "NvimTreeExecFile"
  elseif PICTURE_MAP[self.extension] then
    hl = "NvimTreeImageFile"
  end

  return { str = self.name, hl = { hl } }
end

---Create a sanitized partial copy of a node
---@return FileNode cloned
function FileNode:clone()
  local clone = Node.clone(self) --[[@as FileNode]]

  clone.extension = self.extension

  return clone
end

return FileNode
