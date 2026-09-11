local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local exec_lua = n.exec_lua

-- TODO create doc:
-- - to create expect grid start with   nvim -nu nvt_min.lua --cmd ':set columns=80 lines=24'

describe("map_node_open", function()
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
    -- TODO think about copying contents of an actual directory into tmp rather than copying
    local tmp = t.tmpname(false)
    assert(t.mkdir(tmp))

    assert(t.mkdir(tmp .. "/d1"))
    t.write_file(tmp .. "/d1/f1", "d1f1", true)
    t.write_file(tmp .. "/d1/f2", "d1f2", true)

    assert(t.mkdir(tmp .. "/d2"))

    t.write_file(tmp .. "/f1", "f1", true)
    t.write_file(tmp .. "/f2", "f2", true)

    n.api.nvim_set_current_dir(tmp)

    exec_lua(function()
      require("nvim-tree").setup({
        renderer = {
          root_folder_label = false,
        },
      })
    end)
  end)

  it("map_node_open_dir", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("gg")
    n.feed("<CR>")

    screen:expect({
      attr_ids = {},
      grid = [[
  ^  d1                      │                                                 |
       f1                    │~                                                |
       f2                    │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
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

  it("map_node_open_file", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("<down><down>")
    n.feed("<CR>")

    screen:expect({
      attr_ids = {},
      grid = [[
    d1                      │^f1                                               |
    d2                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
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
NvimTree_1 [-]                 f1                                               |
                                                                                |
    ]],
    })
  end)
end)
