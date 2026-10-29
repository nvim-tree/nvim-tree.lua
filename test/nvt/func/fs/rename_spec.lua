local t = require("test.testutil")
require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each, t.pending = t.describe or describe, t.it or it, t.before_each or before_each, t.pending or pending

--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({
    config = {
      renderer = {
        group_empty = true,
      },
    },
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
  t.it("file name", function()
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
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/f3" } }, history = true, kind = "echomsg" }, },
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}f1                                               |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: f3                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*18
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:/tmp/nvt_func/data/f3                            }|
      ]],
    })
  end)


  t.it("file name exists", function()
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
      messages = { {
        content = { { "[NvimTree] Cannot rename /tmp/nvt_func/data/f1 -> /tmp/nvt_func/data/f2: file already exists", 19, "WarningMsg" } },
        history = true,
        kind = "echomsg"
      } },
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}f1                                               |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*18
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:f1                                               }|
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
       d1f1                  │~                                                |
    d2                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*16
NvimTree_1 [-]                 /tmp/nvt_func/data/d1/d1d2/fz                    |
]],
    })
  end)


  -- BUG attempts to rename to root instead of cancelling
  t.pending("file name cancel", function()
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
end)

-- vim:colorcolumn=80
