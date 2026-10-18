local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({ data = "test/nvt/func/fs/move/data", })
end)


t.describe("fs.move", function()
  t.it("nothing", function()
    n.fn.setreg("+", "")

    nf.feed_sync({
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


  t.it("inexistent", function()
    n.fn.setreg("+", "/tmp/nvt_func/data/inexistent")

    nf.feed_sync({
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


  t.it("present", function()
    n.fn.setreg("+", "/tmp/nvt_func/data/src/f1")

    nf.feed_sync({
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

    na.dir_exists("/tmp/nvt_func/data/dst")
    na.file_exists("/tmp/nvt_func/data/dst/f1")
    na.not_path_exists("/tmp/nvt_func/data/src/f1")
  end)
end)

-- vim:colorcolumn=80
