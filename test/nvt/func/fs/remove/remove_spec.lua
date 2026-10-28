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
  t.it("single file actions.remove_file.close_window = true", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<CR>",
      "<down>",
      "<CR>",
      "<C-w><C-v>",
      ":e f 1<CR>",
      ":NvimTreeFocus<CR>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove d 2 f 1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d 2/d 2 f 1 was properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │^f 1                                              |
    d 1                     │~                                                |
    d 2                     │~                                                |
    d 2 link ➛ d 2          │~                                                |
    d 3                     │~                                                |
     f 1                     │~                                                |
     f 1 link ➛ f 1          │~                                                |
~                             │~                                                |*16
NvimTree_1 [-]                 f 1                                              |
      ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d 2/d 2 f 1")
    na.not_buf_exists("/tmp/nvt_func/data/d 2/d 2 f 1")

    na.events_received({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 2/d 2 f 1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d 2/d 2 f 1", }, },
    })
  end)


  t.it("empty dir", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove d 2? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
      "gg",
      "E",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/d 2 was properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
      d 1 d 1               │~                                                |
         d 1 d 1 f 1         │~                                                |
      d 1 d 2               │~                                                |
         d 1 d 2 f 1         │~                                                |
    d 2 link ➛ d 2          │~                                                |
    d 3                     │~                                                |
       d 3 f 1               │~                                                |
     f 1                     │~                                                |
     f 1 link ➛ f 1          │~                                                |
~                             │~                                                |*12
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d 2")

    na.events_received({
      { event_type = "FolderRemoved", payload = { folder_name = "/tmp/nvt_func/data/d 2", }, },
    })
  end)


  t.it("recursive dir", function()
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
    d 2 link ➛ d 2          │~                                                |
       d 2 f 1               │~                                                |
    d 3                     │~                                                |
       d 3 f 1               │~                                                |
     f 1                     │~                                                |
     f 1 link ➛ f 1          │~                                                |
~                             │~                                                |*14
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d 1")

    na.not_path_exists("/tmp/nvt_func/data/d 1/d 1 d 1")
    na.not_path_exists("/tmp/nvt_func/data/d 1/d 1 d 1/d 1 d 1 f 1")

    na.not_path_exists("/tmp/nvt_func/data/d 1/d 1 d 2")
    na.not_path_exists("/tmp/nvt_func/data/d 1/d 1 d 2/d 1 d 2 f 1")

    na.events_received({
      { event_type = "FolderRemoved", payload = { folder_name = "/tmp/nvt_func/data/d 1", }, },
    })
  end)


  t.it("single file link", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down><down><down>",
      "<CR>",
      ":NvimTreeFocus<CR>", -- opens f 1, not f 1 link
      "<down>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove f 1 link? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] /tmp/nvt_func/data/f 1 link was properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │f 1                                              |
    d 1                     │~                                                |
    d 2                     │~                                                |
    d 2 link ➛ d 2          │~                                                |
    d 3                     │~                                                |
  ^   f 1                     │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 f 1                                              |
      ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/f 1 link")
    na.buf_exists("/tmp/nvt_func/data/f 1") -- buffer is f 1, not f 1 link

    na.events_received({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/f 1 link", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/f 1 link", }, },
    })
  end)


  t.it("many", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<CR>",
      "<down>",
      "<s-v>",
      "<down><down><down>",
      "<Del>",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Remove 4 selected? y/N: ", content = { { "" } }, pos = 0, } },
      showmode = { { "-- VISUAL LINE --", "ModeMsg" } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] 4 nodes properly removed." } }, history = true, kind = "echomsg" }, },
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
    d 2                     │~                                                |
  ^   f 1 link ➛ f 1          │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.events_received_unordered({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 2/d 2 f 1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d 2/d 2 f 1", }, },

      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 2 link", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d 2 link", }, },

      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/f 1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/f 1", }, },

      { event_type = "FolderRemoved",  payload = { folder_name = "/tmp/nvt_func/data/d 3", }, },
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d 2")
    na.path_exists("link",      "/tmp/nvt_func/data/f 1 link")

    na.not_path_exists("/tmp/nvt_func/data/d 2/d 2 f 1")
    na.not_path_exists("/tmp/nvt_func/data/d 2 link")
    na.not_path_exists("/tmp/nvt_func/data/d 3")
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
      d 1 d 1               │~                                                |
         d 1 d 1 f 1         │~                                                |
      d 1 d 2               │~                                                |
         d 1 d 2 f 1         │~                                                |
    d 2                     │~                                                |
       d 2 f 1               │~                                                |
    d 2 link ➛ d 2          │~                                                |
       d 2 f 1               │~                                                |
    d 3                     │~                                                |
       d 3 f 1               │~                                                |
     f 1                     │~                                                |
     f 1 link ➛ f 1          │~                                                |
~                             │~                                                |*9
NvimTree_1 [-]                 [No Name]                                        |
      ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d 1")
    na.path_exists("directory", "/tmp/nvt_func/data/d 1/d 1 d 1")
    na.path_exists("file",      "/tmp/nvt_func/data/d 1/d 1 d 1/d 1 d 1 f 1")
    na.path_exists("directory", "/tmp/nvt_func/data/d 1/d 1 d 2")
    na.path_exists("file",      "/tmp/nvt_func/data/d 1/d 1 d 2/d 1 d 2 f 1")

    na.path_exists("directory", "/tmp/nvt_func/data/d 2")
    na.path_exists("file",      "/tmp/nvt_func/data/d 2/d 2 f 1")
    na.path_exists("link",      "/tmp/nvt_func/data/d 2 link")

    na.path_exists("directory", "/tmp/nvt_func/data/d 3")
    na.path_exists("file",      "/tmp/nvt_func/data/d 3/d 3 f 1")

    na.path_exists("file",      "/tmp/nvt_func/data/f 1")

    na.events_received({})
  end)
end)

-- vim:colorcolumn=80
