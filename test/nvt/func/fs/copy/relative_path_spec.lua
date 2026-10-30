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
    data = "test/nvt/func/fs/copy/relative_path_data",
    screen_opts = {
      ext_messages = true,
      ext_linegrid = true,
    },
  })
end)


t.describe("fs.copy.relative_path", function()
  t.it("file", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down><down><down>",
      "Y",
    })

    t.eq("d1/d1d2/d1d2f1", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Copied d1/d1d2/d1d2f1 to system clipboard!" } }, history = true, kind = "echomsg" }, },
    })
  end)


  t.it("dir", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down><down>",
      "Y",
    })

    t.eq("d1/d1d2/", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Copied d1/d1d2/ to system clipboard!" } }, history = true, kind = "echomsg" }, },
    })
  end)


  t.it("root", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<C-]>",
      "<up>",
      "Y",
    })

    t.eq("/", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Copied / to system clipboard!" } }, history = true, kind = "echomsg" }, },
    })
  end)
end)

-- vim:colorcolumn=80
