local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local command = n.command
local exec_lua = n.exec_lua

describe("api_open", function()
  --- @type test.functional.ui.screen
  local screen

  setup(function()
    -- TODO this can be done without -u and a direct vim.pack.add
    clear({ args_rm = { "-u" } })

    command("packadd nvim-tree.lua")

    screen = Screen.new(40, 20)
  end)

  before_each(function()
    -- TODO think about copying contents of an actual directory into tmp rather than copying
    local tmp = t.tmpname(false)
    assert(t.mkdir(tmp))
    t.write_file(tmp .. "/file1", "foo", true)
    t.write_file(tmp .. "/file2", "bar", true)
    assert(t.mkdir(tmp .. "/dir1"))
    assert(t.mkdir(tmp .. "/dir2"))

    command(":cd " .. tmp)

    -- TODO try and use a function, not a lua string, if we have luals issues
    exec_lua([[
      require("nvim-tree").setup({
        renderer = {
          root_folder_label = false,
        },
      })
      ]])
  end)

  local function nvt_hl_attr_ids()
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

    return attr_ids
  end

  it("api_tree_open_populated", function()
    exec_lua([[
      local api = require("nvim-tree.api")
      api.tree.open()
      ]])

    -- TODO setting all hl groups causes expect to take much longer to execute
    local attr_ids = nvt_hl_attr_ids()
    screen:add_extra_attr_ids(attr_ids)

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
end)
