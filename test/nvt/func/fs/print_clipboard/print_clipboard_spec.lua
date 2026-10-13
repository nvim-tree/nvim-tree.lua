local t = require("test.testutil")
local n = require("test.functional.testnvim")()
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
  screen = nf.create_session()
end)


describe("fs.print_clipboard", function()
  it("none", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
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
                                                                                |
[NvimTree]                                                                      |
                                                                                |
Press ENTER or type command to continue^                                         |
    ]],
    })

  end)


  it("many", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "c",
      "<down>",
      "x",
      "<down>",
      "c",
      "<down>",
      "x",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
                                                                                |
[NvimTree]                                                                      |
Cut                                                                             |
 * /tmp/nvt_func/data/d1/d1f2                                                   |
 * /tmp/nvt_func/data/d3                                                        |
Copy                                                                            |
 * /tmp/nvt_func/data/d1/d1f1                                                   |
 * /tmp/nvt_func/data/d2                                                        |
Press ENTER or type command to continue^                                         |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
