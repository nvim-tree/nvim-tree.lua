local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT
local view = require "nvim-tree.view"

local Decorator = require "nvim-tree.renderer.decorator"

---@class DecoratorSize: Decorator
---@field width_cutoff integer
---@field noshow_folder_size_glyph string
---@field column_width integer
---@field show_folder_size boolean
---@field units string[]
---@field format_unit function
---@field format_size function
local DecoratorSize = Decorator:new()

---@param opts table
---@return DecoratorSize
function DecoratorSize:new(opts)
  local o = Decorator.new(self, {
    enabled = opts.renderer.size.enable,
    hl_pos = HL_POSITION.none,
    icon_placement = ICON_PLACEMENT.right_align,
  })
  ---@cast o DecoratorSize

  if not o.enabled then
    return o
  end

  o.width_cutoff = opts.renderer.size.width_cutoff
  o.noshow_folder_size_glyph = opts.renderer.size.noshow_folder_size_glyph or ""
  o.column_width = opts.renderer.size.column_width
  o.show_folder_size = opts.renderer.size.show_folder_size
  o.units = { "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB" }

  -- Guaranteed to be a function from previous setup
  o.format_unit = opts.renderer.size.format_unit
  o.format_size = function(size)
    local formatted = string
      .format("%.2f", size)
      -- Remove trailing zeros after the decimal point
      :gsub("(%..-)0+$", "%1")
      -- Remove the trailing decimal point if it's a whole number
      :gsub("%.$", "")
    return formatted
  end

  return o
end

--- Convert a size to a human-readable format (e.g., KB, MB, GB) with fixed width
---@private
---@param size number size in bytes
---@return string
--- edit: Since then I've moved a lot of ifs around getting down to only three, but I'll keep the comment bellow just in case.
---NOTE: This function still try it's best to minified the string
--- generated, but this implies that we have some branches
--- to determined how much bytes can we shave from the string to
--- comply to `self.column_width`.
--- Since we know `self.column_width` doesn't change, a better way could be
--- decide a version of 'human_readable_size' a priori, based
--- on `self.column_width` *once* at this object's construction.
--- Basically, instead of this method, we would "baking" all ifs first
--- to decide which function to bind to possible field `self.human_readable_size`.
function DecoratorSize:human_readable_size(size)
  -- Check for nan, negative, etc.
  if type(size) ~= "number" or size ~= size or size < 0 then
    return ""
  end
  local index = 1

  -- We check for index here because for exaple, let's say
  -- on a given iteration you have :
  -- 1024 YB, then index is equal to #units, normally we would devide again,
  -- but we don't have more units, so keep as is.
  while size >= 1024 and index < #self.units do
    size = size / 1024
    index = index + 1
  end

  local unit_str = self.format_unit(self.units[index])

  -- Apparently string.format already rounds then number
  local size_str = self.format_size(size)
  local result = size_str .. unit_str

  -- We Need a max length to align size redering properly
  -- So the result must have at most this column width
  local max_length = self.column_width

  if #result > max_length then
    if index <= #self.units then
      size = size / 1024
      index = index + 1
      size_str = self.format_size(size)
      unit_str = self.format_unit(self.units[index])
      result = size_str .. unit_str
      -- Now that we divided one more time to make it even smaller
      -- we are garanteed the size string to have lenght of <= 4 (from 0.xx size)
      assert(#size_str <= 4)
    end
  end

  -- After we're sure we divided as much as we can when we
  -- actually need it, only then we add the padding of max_length
  result = string.format("%" .. max_length .. "s", result)

  -- If still too big after all that,
  -- then we just set to empty string
  if #result > max_length then
    result = string.format("%" .. max_length .. "s", "")
  end

  return result
end

---@param node Node
---@return HighlightedString[]|nil icons
function DecoratorSize:calculate_icons(node)
  if not self.enabled or view.get_current_width() < self.width_cutoff then
    return nil
  end

  local size = node and node.fs_stat and node.fs_stat.size or 0
  local folder_size_str = self.column_width > 0 and (string.rep(" ", self.column_width - 1) .. self.noshow_folder_size_glyph) or ""
  local icon = {
    str = (self.show_folder_size or node.nodes == nil) and self:human_readable_size(size) or folder_size_str,
    hl = { "NvimTreeFileSize" },
  }
  return { icon }
end

return DecoratorSize
