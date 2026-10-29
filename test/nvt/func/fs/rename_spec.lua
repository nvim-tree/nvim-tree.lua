local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each

--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({
    data = "test/nvt/func/fs/rename_data",
    screen_opts = {
      ext_cmdline = true,
      ext_messages = true,
      ext_linegrid = true,
    },
  })

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.WillRenameNode)
  nf.event_subscribe(Event.NodeRenamed)
end)


t.describe("fs.rename", function()
  t.it("file", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1")
    na.buf_exists("/tmp/nvt_func/data/f1")

    nf.feed_sync({
      "r",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "f1" } }, pos = 2, } },
    })

    nf.feed_sync({
      "<BS>",
      "3",
      "<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f3")
    na.buf_exists("/tmp/nvt_func/data/f3")

    na.not_path_exists("/tmp/nvt_func/data/f1")
    na.not_buf_exists("/tmp/nvt_func/data/f1")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/f3", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/f3", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/f3" } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │f1                                               |
    d1                      │~                                                |
    d2                      │~                                                |
     f2                      │~                                                |
  ^   f3                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 /tmp/nvt_func/data/f3                            |
      ]],
    })
  end)


  t.it("file exists", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1")
    na.buf_exists("/tmp/nvt_func/data/f1")

    nf.feed_sync({
      "r",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "f1" } }, pos = 2, } },
    })

    nf.feed_sync({
      "<BS>",
      "2",
      "<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1")
    na.buf_exists("/tmp/nvt_func/data/f1")

    na.path_exists("file", "/tmp/nvt_func/data/f2")
    na.not_buf_exists("/tmp/nvt_func/data/f2")

    na.events_received({})

    screen:expect({
      attr_ids = {},
      messages = { {
        content = { { "[NvimTree] Cannot rename /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/f2: file already exists", "WarningMsg" } },
        history = true,
        kind = "echomsg"
      } },
      grid = [[
  /tmp/nvt_func/data/..       │f1                                               |
    d1                      │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
  ^   f2                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 f1                                               |
      ]],
    })
  end)


  t.it("file creates directories", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1")
    na.buf_exists("/tmp/nvt_func/data/f1")

    nf.feed_sync({
      "r",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "f1" } }, pos = 2, } },
    })

    nf.feed_sync({
      "<BS><BS>",
      "d1/d1d2/fz",
      "<CR>",
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d1/d1d2")
    na.path_exists("file",      "/tmp/nvt_func/data/d1/d1d2/fz")
    na.buf_exists("/tmp/nvt_func/data/d1/d1d2/fz")

    na.not_path_exists("/tmp/nvt_func/data/f1")
    na.not_buf_exists("/tmp/nvt_func/data/f1")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/d1/d1d2/fz", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/d1/d1d2/fz", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/d1/d1d2/fz" } }, history = true, kind = "echomsg", } },
      grid = [[
  /tmp/nvt_func/data/..       │f1                                               |
    d1                      │~                                                |
      d1d2                  │~                                                |
  ^       fz                  │~                                                |
       d1f1.ext              │~                                                |
    d2                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*16
NvimTree_1 [-]                 /tmp/nvt_func/data/d1/d1d2/fz                    |
]],
    })
  end)


  t.it("file empty", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1")
    na.buf_exists("/tmp/nvt_func/data/f1")

    nf.feed_sync({
      "r",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "f1" } }, pos = 2, } },
    })

    nf.feed_sync({
      "<BS><BS>",
      "<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1")
    na.buf_exists("/tmp/nvt_func/data/f1")

    na.events_received({})

    screen:expect({
      attr_ids = {},
      messages = {},
      unchanged = true,
      grid = [[
  /tmp/nvt_func/data/..       │f1                                               |
    d1                      │~                                                |
    d2                      │~                                                |
  ^   f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 f1                                               |
]],
    })
  end)


  t.it("dir grouped", function()
    n.exec_lua(function()
      require("nvim-tree").setup({
        renderer = {
          group_empty = true,
        },
      })
    end)

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down><down><down>",
      "r",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "d2d1" } }, pos = 4, } },
    })

    nf.feed_sync({
      "x",
      "<CR>",
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d2/d2d1x")
    na.not_path_exists("/tmp/nvt_func/data/d2/d2d1")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/d2/d2d1", new_name = "/tmp/nvt_func/data/d2/d2d1x", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/d2/d2d1", new_name = "/tmp/nvt_func/data/d2/d2d1x", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d2/d2d1 -> /tmp/nvt_func/data/d2/d2d1x" } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1.ext              │~                                                |
  ^  d2/d2d1x                │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })
  end)


  t.it("ignore root", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "r",
    })

    na.path_exists("directory", "/tmp/nvt_func/data")

    na.events_received({})

    screen:expect({
      attr_ids = {},
      cmdline = {},
      messages = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })
  end)
end)


t.describe("fs.rename_basename", function()
  t.it("file", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down><down>",
      "e",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "d1f1" } }, pos = 4, } },
    })

    nf.feed_sync({
      "x",
      "<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/d1/d1f1x.ext")
    na.not_path_exists("/tmp/nvt_func/data/d1/d1f1.ext")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/d1/d1f1.ext", new_name = "/tmp/nvt_func/data/d1/d1f1x.ext", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/d1/d1f1.ext", new_name = "/tmp/nvt_func/data/d1/d1f1x.ext", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d1/d1f1.ext -> /tmp/nvt_func/data/d1/d1f1x.ext" } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^     d1f1x.ext             │~                                                |
    d2                      │~                                                |
      d2d1                  │~                                                |
         d2d1f1              │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*15
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })
  end)
end)


t.describe("fs.rename_full", function()
  t.it("file", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "u",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/f1" } }, pos = 21, } },
    })

    nf.feed_sync({
      "x",
      "<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1x")
    na.not_path_exists("/tmp/nvt_func/data/f1")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/f1x", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/f1x", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/f1x" } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^   f1x                     │~                                                |
     f2                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })
  end)
end)


t.describe("fs.rename_node", function()
  t.it("file", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
    })

    -- schedule this as it blocks on vim.ui.input
    n.exec_lua(function()
      vim.schedule(require("nvim-tree.api").fs.rename_node)
    end)

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "f1" } }, pos = 2, } },
    })

    nf.feed_sync({
      "x",
      "<CR>",
    })

    na.path_exists("file", "/tmp/nvt_func/data/f1x")
    na.not_path_exists("/tmp/nvt_func/data/f1")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/f1x", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/f1", new_name = "/tmp/nvt_func/data/f1x", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/f1x" } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^   f1x                     │~                                                |
     f2                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })
  end)
end)


t.describe("fs.rename_sub", function()
  t.it("file", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<C-r>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })

    nf.feed_sync({
      "x",
      "<CR>",
    })

    na.not_path_exists("/tmp/nvt_func/data/d1/d1f1.ext")
    na.path_exists("file", "/tmp/nvt_func/data/d1/x")

    na.events_received({
      { event_type = "WillRenameNode", payload = { old_name = "/tmp/nvt_func/data/d1/d1f1.ext", new_name = "/tmp/nvt_func/data/d1/x", }, },
      { event_type = "NodeRenamed",    payload = { old_name = "/tmp/nvt_func/data/d1/d1f1.ext", new_name = "/tmp/nvt_func/data/d1/x", }, },
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d1/d1f1.ext -> /tmp/nvt_func/data/d1/x" } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^     x                     │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })
  end)
end)

-- vim:colorcolumn=80
