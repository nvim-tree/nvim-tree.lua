local n = require("test.functional.testnvim")()

local M = {}

-- remove $NVT_FUNC_TMP
-- cd to $NVT_FUNC_TMP
-- if $NVT_FUNC_DATA exists:recursively copy it to $NVT_FUNC_TMP and cd
function M.setup_dirs()
  local tmp = os.getenv("NVT_FUNC_TMP")
  if not tmp then
    return
  end

  -- blow away temp
  print(n.fn.system({ "rm", "-r", "-f", "-v", tmp }))
  print(n.fn.system({ "mkdir", "-p", "-v", tmp }))

  -- always cd to tmp
  n.api.nvim_set_current_dir(tmp)

  local data = os.getenv("NVT_FUNC_DATA")
  if data and vim.uv.fs_stat(data) then
    print(n.fn.system({ "cp", "-p", "-r", "-v", data, tmp }))
    n.api.nvim_set_current_dir(tmp .. "/data")
  end
end

--- Reset all NvimTree* highlight groups to just a unique foreground colour
--- Return attr_ids to match
--- Add a CL variant with the same background colour as NvimTreeCursorLine
--- May be executed repeatedly however results are not idempotent: foreground colours will be different, depending on vim.api.nvim_get_hl iteration order
function M.simple_attr_ids()
  local attr_ids = {}

  -- math.random(tonumber('0x707070'),tonumber('0x909090'))
  local bg_rgb, bg_hex = 8758352, "#85a450"

  -- build the cursor line first, background only
  attr_ids["NvimTreeCursorLine"] = { background = bg_rgb }
  n.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = bg_hex })

  -- unique colour for each group, descending from #fefefe
  local i, r, g, b = 1, 254, 254, 254
  local rgb, hex

  for group, _ in pairs(n.api.nvim_get_hl(0, { create = false })) do
    if group ~= "NvimTreeCursorLine" and group:match("^NvimTree.*") and not group:match(".*CL$") then
      -- next unique fg colour
      rgb = r * 256 * 256 + g * 256 + b
      hex = string.format("#%x", rgb)
      i = i + 1
      if (i % 256 == 0) then
        b = 254
        g = 254
        r = r - 1
      elseif (i % 16 == 0) then
        b = 254
        g = g - 1
      else
        b = b - 1
      end

      -- add the group's concrete definition with fg only
      attr_ids[group] = { foreground = rgb }
      n.api.nvim_set_hl(0, group, { fg = hex })

      -- create an NvimTreeCursorLine variant
      attr_ids[group .. "CL"] = { foreground = rgb, background = bg_rgb }
      n.api.nvim_set_hl(0, group .. "CL", { fg = hex, bg = bg_hex })
    end
  end

  return attr_ids
end

return M
