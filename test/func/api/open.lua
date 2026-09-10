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

    -- build the cursor line first, background only
    local hl_cursor_line = n.api.nvim_get_hl(0, { name = "NvimTreeCursorLine", link = false })
    assert(hl_cursor_line)
    local attr_cursor_line = { background = hl_cursor_line.bg }
    attr_ids["NvimTreeCursorLine"] = attr_cursor_line

    -- unique colour for each group, descending from #fefefe
    local i = 1
    local r, g, b = 254, 254, 254

    for group, _ in pairs(n.api.nvim_get_hl(0, { create = false })) do
      if group ~= "NvimTreeCursorLine" and group:match("^NvimTree.*") then
        local rgb = r * 256 * 256 + g * 256 + b
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
        -- print(string.format("#%x", rgb))

        -- add the group's concrete definition with fg only
        local attr = { foreground = rgb }
        attr_ids[group] = attr
        n.api.nvim_set_hl(0, group, { fg = string.format("#%x", rgb) })

        -- create an NvimTreeCursorLine variant
        attr_ids[group .. "CL"] = { foreground = rgb, background = hl_cursor_line.bg }
        n.api.nvim_set_hl(0, group .. "CL", { fg = string.format("#%x", rgb), bg = string.format("#%x", hl_cursor_line.bg) })
      end
    end

    return attr_ids
  end

  it("api_tree_open_populated", function()
    exec_lua([[
      local api = require("nvim-tree.api")
      api.tree.open()
      ]])

    -- TODO this takes some time to execute
    screen:add_extra_attr_ids(nvt_hl_attr_ids())

    -- TODO why does file have NvimTreeFolderArrowClosed ?
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
