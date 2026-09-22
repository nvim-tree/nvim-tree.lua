local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local exec_lua = n.exec_lua

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
local setup = t.setup or setup
---@diagnostic enable: undefined-global

-- remove $NVT_FUNC_TMP
-- cd to $NVT_FUNC_TMP
-- if $NVT_FUNC_DATA exists:recursively copy it to $NVT_FUNC_TMP and cd
local function setup_dirs()
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

describe("map_node_open", function()
  --- @type test.functional.ui.screen
  local screen

  setup(function()
    clear()

    screen = Screen.new(80, 24)

    exec_lua(function()
      vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})
    end)

    setup_dirs()
  end)

  before_each(function()
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
  /tmp/nvt_func/data/..       │                                                 |
  ^  d1                      │~                                                |
       f1                    │~                                                |
       f2                    │~                                                |
    d2                      │~                                                |
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
  /tmp/nvt_func/data/..       │^f1                                               |
    d1                      │~                                                |
    d2                      │~                                                |
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
