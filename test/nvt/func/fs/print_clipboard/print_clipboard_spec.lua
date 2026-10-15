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
  screen = nf.create_session({}, nil, nil, { ext_messages = true, })
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
      messages = { { content = { { "[NvimTree]\n\n", } }, history = true, kind = "echomsg", } },
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

    screen:expect({
      messages = {
        { content = { { "[NvimTree] /tmp/nvt_func/data/d1/d1f1 added to clipboard." } }, history = true, kind = "echomsg" },
        { content = { { "[NvimTree] /tmp/nvt_func/data/d1/d1f2 added to clipboard." } }, history = true, kind = "echomsg" },
        { content = { { "[NvimTree] /tmp/nvt_func/data/d2 added to clipboard." } },      history = true, kind = "echomsg" },
        { content = { { "[NvimTree] /tmp/nvt_func/data/d3 added to clipboard." } },      history = true, kind = "echomsg" },
      },
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      messages = { {
        history = true,
        kind = "echomsg",
        content = { { [[[NvimTree]
Cut
 * /tmp/nvt_func/data/d1/d1f2
 * /tmp/nvt_func/data/d3
Copy
 * /tmp/nvt_func/data/d1/d1f1
 * /tmp/nvt_func/data/d2
]], } },
      } },
    })
  end)
end)

-- vim:colorcolumn=80
