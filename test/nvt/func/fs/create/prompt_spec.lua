local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each ---@diagnostic disable-line: inject-field, undefined-global

--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session(nil, nil, nil, { ext_cmdline = true })
end)


t.describe("fs.create prompt", function()
  t.it("tree focused", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "a",
    })

    screen:expect({
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })
  end)


  t.it("api tree not focused", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "<c-w><c-w>",
    })

    -- schedule this as it blocks on vim.ui.input
    n.exec_lua(function()
      vim.schedule(require("nvim-tree.api").fs.create)
    end)

    -- wait for the input
    n.poke_eventloop()

    screen:expect({
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })
  end)


  t.it("file focused", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down><Down>",
      "a",
    })

    screen:expect({
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })
  end)


  t.it("cancelled", function()
    nf.feed_sync({
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
