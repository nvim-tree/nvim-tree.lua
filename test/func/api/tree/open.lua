local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local exec_lua = n.exec_lua

-- TODO extract nvt test utils

--- Reset all NvimTree* highlight groups to just a unique foreground colour
--- Add a CL variant with the same background colour as NvimTreeCursorLine
--- May be executed repeatedly however results are not idempotent: foreground colours will be different, depending on vim.api.nvim_get_hl iteration order
--- @param screen test.functional.ui.screen
local function nvt_hl_attr_ids(screen)
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

  screen:add_extra_attr_ids(attr_ids)
end

describe("api_tree_open", function()
  --- @type test.functional.ui.screen
  local screen

  setup(function()
    clear()

    screen = Screen.new(80, 24)

    exec_lua(function()
      vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})
    end)
  end)

  before_each(function()
    local nvt_test_data = os.getenv("NVT_TEST_DATA")
    if nvt_test_data then
      n.api.nvim_set_current_dir(nvt_test_data)
    end

    -- TODO helper to test root folder name
    exec_lua(function()
      require("nvim-tree").setup({
        renderer = {
          root_folder_label = false,
        },
      })
    end)

    nvt_hl_attr_ids(screen)
  end)

  it("populated_unfocussed_text_only", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("<c-w><c-w>")

    screen:expect({
      attr_ids = {},
      grid = [[
    dir1                    │^                                                 |
    dir2                    │~                                                |
     file1                   │~                                                |
     file2                   │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)

  it("populated_focussed", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    -- TODO NvimTreeFolderArrowClosed is always set by Padding:get_arrows, it should only be set for DirectoryNode
    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeEmptyFolderNameCL:dir1}{NvimTreeNormalCL:                    }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeEmptyFolderName:dir2}{NvimTreeNormal:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: file1                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: file2                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*18
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
                                                                                |
    ]],
    })
  end)

  it("populated_unfocussed", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("<down>")
    n.feed("<c-w><c-w>")

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormalNC: }{NvimTreeEmptyFolderName:dir1}{NvimTreeNormalNC:                    }{NvimTreeWinSeparator:│}^                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL: }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalNCCL: }{NvimTreeEmptyFolderNameCL:dir2}{NvimTreeNormalNCCL:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormalNC: file1                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormalNC: file2                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*18
{NvimTreeStatusLineNC:NvimTree_1 [-]                 }{3:[No Name]                                        }|
                                                                                |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
