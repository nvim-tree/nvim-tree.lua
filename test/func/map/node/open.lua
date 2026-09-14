local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local exec_lua = n.exec_lua

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
    -- TODO maybe recursively copy contents
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
  end)

  it("dir", function()
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

  it("file", function()
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

-- vim:colorcolumn=80
