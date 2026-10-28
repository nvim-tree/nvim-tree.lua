local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({
    data = "test/nvt/func/fs/print_clipboard_data",
    screen_opts = {
      ext_messages = true,
      ext_linegrid = true
    },
  })
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
      attr_ids = {},
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
      attr_ids = {},
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
      attr_ids = {},
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
