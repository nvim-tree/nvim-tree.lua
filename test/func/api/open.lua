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

  local function nvt_hl_attr_ids(hl_groups)
    local attr_ids = {}

    -- build the cursor line first
    local hl_cursor_line = n.api.nvim_get_hl(0, { name = "NvimTreeCursorLine", link = false })
    assert(hl_cursor_line)
    local attr_cursor_line = { foreground = hl_cursor_line.fg, background = hl_cursor_line.bg }
    attr_ids["NvimTreeCursorLine"] = attr_cursor_line

    for group in pairs(n.api.nvim_get_hl(0, {})) do
      if vim.tbl_contains(hl_groups, group) and group ~= "NvimTreeCursorLine" then
        -- add the group's concrete definition
        local hl = n.api.nvim_get_hl(0, { name = group, link = false })
        local attr = { foreground = hl.fg, background = hl.bg }
        attr_ids[group] = attr

        -- create a CL variant if background differs
        if attr.background ~= attr_cursor_line.background then
          attr_ids[group .. "CL"] = vim.tbl_extend("force", attr_ids[group], attr_ids["NvimTreeCursorLine"])
        end
      end
    end

    return attr_ids
  end

  it("api_tree_open_populated", function()
    exec_lua([[
      local api = require("nvim-tree.api")
      api.tree.open()
      ]])

    screen:add_extra_attr_ids(nvt_hl_attr_ids({
      "NvimTreeFolderName",
      "NvimTreeFolderIcon",
      "NvimTreeCursorLine",
    }))

    screen:expect({
      grid = [[
        {NvimTreeFolderIconCL:^ }{NvimTreeCursorLine: }{NvimTreeFolderNameCL:dir1}{NvimTreeCursorLine:                    }│         |
        {NvimTreeFolderIcon: } {NvimTreeFolderName:dir2}                    │{1:~        }|
        {NvimTreeFolderIcon:  } file1                   │{1:~        }|
        {NvimTreeFolderIcon:  } file2                   │{1:~        }|
      {1:~                             }│{1:~        }|*14
      {3:NvimTree_1 [-]                 }{2:<o Name] }|
                                              |
    ]],
    })
  end)
end)
