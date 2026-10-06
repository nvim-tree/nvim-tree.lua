local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")
local n = require("test.functional.testnvim")()

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global

--- @type test.functional.ui.screen
local screen


before_each(function()
  screen = nf.create_session(nil, nil, nil, { ext_cmdline = true })
end)


describe("fs.paste.node cut", function()
  it("cut single dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "x",
      "<down>",
      "p",
      "E"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d2                      │~                                                |
  ^    d1                    │~                                                |
         d1f1                │~                                                |
         d1f2                │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*13
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1 added to clipboard.                            |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f2")

    na.not_path_exists("/tmp/nvt_func/data/d1")
  end)


  it("cut single file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "<down>",
      "x",
      "<up>",
      "p"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
  ^     f1                    │~                                                |
     f2                      │~                                                |
~                             │~                                                |*15
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d3/f1")

    na.not_path_exists("/tmp/nvt_func/data/f1")
  end)
end)

-- vim:colorcolumn=80
