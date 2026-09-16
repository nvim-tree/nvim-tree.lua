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
    local nvt_test_data = os.getenv("NVT_DIR_TEST_DATA")
    if nvt_test_data then
      n.api.nvim_set_current_dir(nvt_test_data)
    end

    exec_lua(function()
      require("nvim-tree").setup({})
    end)
  end)

  it("dir", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("gg")
    n.feed("<Down>")
    n.feed("<CR>")

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_test_func/data/..  │                                                 |
  ^  d1                      │~                                                |
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
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)

  it("file", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("<down><down><down>")
    n.feed("<CR>")

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_test_func/data/..  │^f1                                               |
    d1                      │~                                                |
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
NvimTree_1 [-]                 f1                                               |
                                                                                |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
