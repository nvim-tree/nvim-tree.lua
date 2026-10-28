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
    data = "test/nvt/func/fs/copy/filename_data",
    screen_opts = {
      ext_messages = true,
      ext_linegrid = true,
    },
  })
end)


t.describe("fs.filename", function()
  t.it("file", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down><down>",
      "y",
    })

    t.eq("d1f1.ext", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Copied d1f1.ext to system clipboard!" } }, history = true, kind = "echomsg" }, },
    })
  end)


  t.it("root", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<C-]>",
      "<up>",
      "y",
    })

    t.eq("d1.ext", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Copied d1.ext to system clipboard!" } }, history = true, kind = "echomsg" }, },
    })
  end)
end)

-- vim:colorcolumn=80
