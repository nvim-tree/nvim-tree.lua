local t = require("test.testutil")
local nf = require("test.functional.nvt.fixtures")
local na = require("test.functional.nvt.asserts")
local n = require("test.functional.testnvim")()

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global

--- @type test.functional.ui.screen
local screen


-- TODO
-- test events
-- test creating in an illegal location e.g. /foo


before_each(function()
  screen = nf.create_session({ ext_cmdline = true })
end)


describe("prompt", function()
  before_each(function()
    n.exec_lua(function()
      require("nvim-tree").setup({})
    end)
  end)

  it("prompt", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })
  end)
end)


describe("single file", function()
  before_each(function()
    n.exec_lua(function()
      require("nvim-tree").setup({})
    end)
  end)


  it("direct ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "direct<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^   direct                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/direct was properly created                       |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/direct")
  end)


  it("indirect ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
  ^     indirect              │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/indirect was properly created                  |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d1/indirect")
  end)


  it("existing file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "f1<CR>"
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

    na.file_exists("/tmp/nvt_func/data/f1")
  end)


  it("existing dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1<CR>"
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

    na.dir_exists("/tmp/nvt_func/data/d1")
  end)
end)

-- vim:colorcolumn=80
