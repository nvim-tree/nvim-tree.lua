local n = require("test.functional.testnvim")()
local t = require("test.testutil")
local Screen = require("test.functional.ui.screen")
local eq = t.eq
local clear = n.clear
local exec_lua = n.exec_lua

-- TODO extract nvt test utils

-- TODO file system state persists between tests; consider a mechanism to copy a fresh data directory before each or all

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
  n.api.nvim_set_current_dir(os.getenv("NVT_TMP_FUNC_DATA") or "")

  exec_lua(function()
    require("nvim-tree").setup({})
  end)
end)

describe("single", function()
  it("direct", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "direct/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^  direct                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/direct/ was properly created                      |
    ]],
    })

    local stat, err = vim.uv.fs_stat("/tmp/nvt_func/data/direct")
    eq(err,                nil)
    eq(stat and stat.type, "directory")
  end)

  it("indirect", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a",
      "d1/indirect/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^    indirect              │~                                                |
       d1f1                  │~                                                |
    direct                  │~                                                |
     f1                      │~                                                |
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
[NvimTree] /tmp/nvt_func/data/d1/indirect/ was properly created                 |
    ]],
    })

    local stat, err = vim.uv.fs_stat("/tmp/nvt_func/data/d1/indirect")
    eq(err,                nil)
    eq(stat and stat.type, "directory")
  end)

  it("dir_exists", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a",
      "d1/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    direct                  │~                                                |
     f1                      │~                                                |
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
[NvimTree] Cannot create: file already exists                                   |
    ]],
    })
  end)

  it("file_exists", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a",
      "d1/d1f1/<CR>"
    )

    -- TODO BUG this fails but shows message "/tmp/nvt_func/data/d1/d1f1/ was properly created"
    --     screen:expect({
    --       attr_ids = {},
    --       grid = [[
    --   ^/tmp/nvt_func/data/..       │                                                 |
    --     d1                      │~                                                |
    --     direct                  │~                                                |
    --      f1                      │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- NvimTree_1 [-]                 [No Name]                                        |
    -- [NvimTree] Cannot create: file already exists                                   |
    --     ]],
    --     })
  end)
end)

-- vim:colorcolumn=80
