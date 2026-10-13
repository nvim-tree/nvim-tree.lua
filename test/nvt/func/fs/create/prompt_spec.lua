local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
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
  screen = nf.create_session(nil, nil, nil, { ext_cmdline = true })
end)


describe("fs.create prompt", function()
  it("tree focused", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "a",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })
  end)


  it("api tree not focused", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "<c-w><c-w>",
      -- TODO why can't we execute this from exec_lua ?
      ":lua require('nvim-tree.api').fs.create()<CR>",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })
  end)


  it("file focused", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down><Down>",
      "a",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })
  end)


  it("cancelled", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "foo",
      "<Esc>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
