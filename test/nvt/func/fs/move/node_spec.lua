local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")
local nu = require("test.nvt.func.util")

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global


--- @type test.functional.ui.screen
local screen


before_each(function()
  screen = nf.create_session()
end)
   

describe("fs.move", function()
  it("nothing", function()
    n.fn.setreg("+", "")

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "gp",
      "E",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    dst                     │~                                                |
       f2                    │~                                                |
    src                     │~                                                |
       f1                    │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
:NvimTreeOpen                                                                   |
    ]],
    })
  end)


  it("inexistent", function()
    n.fn.setreg("+", "/tmp/nvt_func/data/inexistent")

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "gp",
      "E",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    dst                     │~                                                |
       f2                    │~                                                |
    src                     │~                                                |
       f1                    │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
:NvimTreeOpen                                                                   |
    ]],
    })
  end)


  it("present", function()
    n.fn.setreg("+", "/tmp/nvt_func/data/src/f1")

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down>",
      "gp",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    dst                     │~                                                |
  ^     f1                    │~                                                |
       f2                    │~                                                |
    src                     │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
:NvimTreeOpen                                                                   |
    ]],
    })

    -- TODO remove hardcoding
    na.dir_exists("/tmp/nvt_func/data/dst")
    na.file_exists("/tmp/nvt_func/data/dst/f1")
    na.not_path_exists("/tmp/nvt_func/data/src/f1")
  end)
end)

-- vim:colorcolumn=80
