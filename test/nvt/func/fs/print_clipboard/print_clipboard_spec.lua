local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each ---@diagnostic disable-line: inject-field, undefined-global


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({}, nil, nil, { ext_messages = true, })
end)


t.describe("fs.print_clipboard", function()
  t.it("none", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      messages = { { content = { { "[NvimTree]\n\n", } }, history = true, kind = "echomsg", } },
    })
  end)


  t.it("many", function()
    nf.feed_sync({
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
