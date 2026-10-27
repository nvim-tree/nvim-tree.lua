local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({
    data = "test/nvt/func/fs/remove/data",
    screen_opts = {
      ext_cmdline = true,
      ext_messages = true,
      ext_linegrid = true
    },
  })

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.FileRemoved)
  nf.event_subscribe(Event.WillRemoveFile)
  nf.event_subscribe(Event.FolderRemoved)
end)


t.describe("fs.remove", function()
  t.it("single file buffer deleted", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove d 1 f 1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d 1/d 1 f 1 was properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..                                                         |
    d 1                                                                       |
  ^  d 2                                                                       |
     f 1                                                                       |
~                                                                               |*20
      ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d 1/d 1 f 1")
    na.not_buf_exists("/tmp/nvt_func/data/d 1/d 1 f 1")

    na.events_received({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
    })
  end)

  t.it("single dir", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove d 1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
      "gg",
      "E",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d 1 was properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d 2                     │~                                                |
       d 2 f 1               │~                                                |
     f 1                     │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d 1")

    na.events_received({
      { event_type = "FolderRemoved", payload = { folder_name = "/tmp/nvt_func/data/d 1", }, },
    })
  end)

  t.it("many", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<s-v>",
      "<down><down>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove 3 selected? y/N: ", content = { { "" } }, pos = 0, } },
      showmode = { { "-- VISUAL LINE --", "ModeMsg" } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] 3 nodes properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
  ^  d 1                     │~                                                |
~                             │~                                                |*21
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.events_received_unordered({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/f 1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
      { event_type = "FolderRemoved",  payload = { folder_name = "/tmp/nvt_func/data/d 2", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/f 1", }, },
    })

    na.not_path_exists("/tmp/nvt_func/data/d 1/d 1 f 1")
    na.not_path_exists("/tmp/nvt_func/data/d 2")
    na.not_path_exists("/tmp/nvt_func/data/f 1")
  end)

  t.it("ignore root", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Del>",
      "E",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
       d 1 f 1               │~                                                |
    d 2                     │~                                                |
       d 2 f 1               │~                                                |
     f 1                     │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d 1")
    na.file_exists("/tmp/nvt_func/data/d 1/d 1 f 1")
    na.dir_exists("/tmp/nvt_func/data/d 2")
    na.file_exists("/tmp/nvt_func/data/d 2/d 2 f 1")
    na.file_exists("/tmp/nvt_func/data/f 1")

    na.events_received({})
  end)
end)

-- vim:colorcolumn=80
