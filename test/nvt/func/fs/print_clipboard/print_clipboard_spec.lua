local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local nu = require("test.nvt.func.util")

-- 0.12 global compatibility, remove when 0.13 is stable
---@diagnostic disable: undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each
---@diagnostic enable: undefined-global


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session()
end)


t.describe("fs.print_clipboard", function()
  t.it("none", function()
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


  t.it("many", function()
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
