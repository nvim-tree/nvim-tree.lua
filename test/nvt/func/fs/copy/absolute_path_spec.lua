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
    data = "test/nvt/func/fs/copy/absolute_path_data",
    screen_opts = {
      ext_messages = true,
      ext_linegrid = true,
    },
  })
end)


t.describe("fs.copy.absolute_path", function()
  t.it("single file", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down><down>",
      "gy",
    })

    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Copied /tmp/nvt_func/data/f1 to system clipboard!" } }, history = true, kind = "echomsg" }, },
    })
  end)


  t.it("multiple", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down><down><down>",
      "<CR>",
      "<up><up>",
      "<S-v>",
      "<down><down><down><down>",
      "gy",
    })

    t.eq([[
/tmp/nvt_func/data/d1/d1f1
/tmp/nvt_func/data/d2/
/tmp/nvt_func/data/d3/
/tmp/nvt_func/data/f1]], n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] 4 absolute paths copied to register" } }, history = true, kind = "echomsg" }, },
    })
  end)
end)

-- vim:colorcolumn=80
