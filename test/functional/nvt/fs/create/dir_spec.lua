local t = require("test.testutil")
local nf = require("test.functional.nvt.fixtures")
local n = require("test.functional.testnvim")()
local eq = t.eq

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global

--- @type test.functional.ui.screen
local screen

before_each(function()
  screen = nf.create_session({ ext_cmdline = true })
end)

describe("single dir", function()
  before_each(function()
    n.exec_lua(function()
      require("nvim-tree").setup({})
    end)
  end)

  it("direct ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })

    n.feed(
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

  it("indirect ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })

    n.feed(
      "d1/indirect/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^    indirect              │~                                                |
       d1f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/indirect/ was properly created                 |
    ]],
    })

    local stat, err = vim.uv.fs_stat("/tmp/nvt_func/data/d1/indirect")
    eq(err,                nil)
    eq(stat and stat.type, "directory")
  end)

  it("existing dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })

    n.feed(
      "d1/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] Cannot create: file already exists                                   |
      ]],
    })
  end)

  it("existing file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })

    n.feed(
      "d1/d1f1/<CR>"
    )

    -- TODO BUG this fails but shows message "/tmp/nvt_func/data/d1/d1f1/ was properly created" and focuses the file
    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^     d1f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/d1f1/ was properly created                     |
        ]],
    })
  end)
end)

-- vim:colorcolumn=80
