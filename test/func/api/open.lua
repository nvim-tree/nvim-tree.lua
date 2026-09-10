local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local exec_lua = n.exec_lua

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
    if group ~= "NvimTreeCursorLine" and group:match("^NvimTree.*") then
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

describe("api_open", function()
  --- @type test.functional.ui.screen
  local screen

  setup(function()
    clear()

    exec_lua(function()
      vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})

      require("nvim-tree").setup({
        renderer = {
          root_folder_label = false,
        },
      })
    end)

    screen = Screen.new(40, 20)

    nvt_hl_attr_ids(screen)
  end)

  before_each(function()
    -- TODO think about copying contents of an actual directory into tmp rather than copying
    local tmp = t.tmpname(false)
    assert(t.mkdir(tmp))
    t.write_file(tmp .. "/file1", "foo", true)
    t.write_file(tmp .. "/file2", "bar", true)
    assert(t.mkdir(tmp .. "/dir1"))
    assert(t.mkdir(tmp .. "/dir2"))

    n.api.nvim_cmd({ cmd = "cd", args = { tmp } }, {})
  end)

  it("api_tree_open_populated_focussed", function()
    exec_lua(function()
      local api = require("nvim-tree.api")
      api.tree.open()
    end)

    -- TODO NvimTreeFolderArrowClosed is always set by Padding:get_arrows, it should only be set for DirectoryNode
    screen:expect({
      grid = [[
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeEmptyFolderNameCL:dir1}{NvimTreeNormalCL:                    }{NvimTreeWinSeparator:│}         |
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeEmptyFolderName:dir2}{NvimTreeNormal:                    }{NvimTreeWinSeparator:│}{1:~        }|
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: file1                   }{NvimTreeWinSeparator:│}{1:~        }|
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: file2                   }{NvimTreeWinSeparator:│}{1:~        }|
      {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~        }|*14
      {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:<o Name] }|
                                              |
    ]],
    })
  end)

  it("api_tree_open_populated_unfocussed", function()
    -- TODO consider resetting tree after each test, they are order dependent
    -- exec_lua(function()
    --   local api = require("nvim-tree.api")
    --   api.tree.open()
    -- end)

    n.feed("<c-w><c-w>")

    screen:expect({
      grid = [[
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL: }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalNCCL: }{NvimTreeEmptyFolderNameCL:dir1}{NvimTreeNormalNCCL:         }{NvimTreeWinSeparator:│}^                    |
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormalNC: }{NvimTreeEmptyFolderName:dir2}{NvimTreeNormalNC:         }{NvimTreeWinSeparator:│}{1:~                   }|
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormalNC: file1        }{NvimTreeWinSeparator:│}{1:~                   }|
      {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormalNC: file2        }{NvimTreeWinSeparator:│}{1:~                   }|
      {NvimTreeEndOfBuffer:~                  }{NvimTreeWinSeparator:│}{1:~                   }|*14
      {NvimTreeStatusLineNC:NvimTree_1 [-]      }{3:[No Name]           }|
                                              |
    ]],
    })
  end)
end)
