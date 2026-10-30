local t = require("test.testutil")
require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


---@param config nvim_tree.config
---@return test.functional.ui.screen
local function create_trash_session(config)
  screen = nf.create_session({
    config = config,
    data = "test/nvt/func/fs/trash_data",
    screen_opts = {
      ext_messages = true,
      ext_cmdline = false,
      ext_linegrid = true
    },
  })

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.FileRemoved)
  nf.event_subscribe(Event.WillRemoveFile)
  nf.event_subscribe(Event.FolderRemoved)

  return screen
end


t.describe("fs.trash", function()
  t.it("single file buffer deleted", function()
    screen = create_trash_session({
      trash = {
        cmd = "rm -rf ",
      }
    })

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Trash d 1 f 1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..                                                         |
    d 1                                                                       |
  ^  d 2                                                                       |
     f 1                                                                       |
     trash_fail.sh                                                             |
~                                                                               |*19
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
    screen = create_trash_session({
      trash = {
        cmd = "rm -rf ",
      }
    })

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Trash d 1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
      "gg",
      "E",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d 2                     │~                                                |
       d 2 f 1               │~                                                |
     f 1                     │~                                                |
     trash_fail.sh           │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d 1")

    na.events_received({
      { event_type = "FolderRemoved", payload = { folder_name = "/tmp/nvt_func/data/d 1", }, },
    })
  end)


  t.it("many", function()
    screen = create_trash_session({
      trash = {
        cmd = "rm -rf ",
      }
    })

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<s-v>",
      "<down><down>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Trash 3 selected? y/N: ", content = { { "" } }, pos = 0, } },
      showmode = { { "-- VISUAL LINE --", "ModeMsg" } },
    })

    nf.feed_sync({
      "y<CR>",
      "gg",
      "E",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
     trash_fail.sh           │~                                                |
~                             │~                                                |*20
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


  t.it("invalid trash.cmd", function()
    screen = create_trash_session({
      trash = {
        cmd = "foobarbaz",
      }
    })

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Trash d 1 f 1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
  ^     d 1 f 1               │~                                                |
    d 2                     │~                                                |
     f 1                     │~                                                |
     trash_fail.sh           │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
    ]],
      messages = { { content = { { "[NvimTree] trash.cmd 'foobarbaz' is not an executable.", "WarningMsg" } }, history = true, kind = "echomsg" }, }
    })

    na.path_exists("file", "/tmp/nvt_func/data/d 1/d 1 f 1")

    na.events_received({})
  end)


  t.it("ignore root", function()
    screen = create_trash_session({})

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
    d 2                     │~                                                |
     f 1                     │~                                                |
     trash_fail.sh           │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
    ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d 1")
    na.path_exists("file", "/tmp/nvt_func/data/d 1/d 1 f 1")
    na.path_exists("directory", "/tmp/nvt_func/data/d 2")
    na.path_exists("file", "/tmp/nvt_func/data/d 2/d 2 f 1")
    na.path_exists("file", "/tmp/nvt_func/data/f 1")

    na.events_received({})
  end)


  t.it("many multiple failures", function()
    screen = create_trash_session({
      trash = {
        -- fails unless "/tmp/nvt_func/data/f 1", prints identical error message as vim.fn.jobstart completion time is nondeterministic
        cmd = "./trash_fail.sh",
      }
    })

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<s-v>",
      "<down><down>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      cmdline = { { prompt = "Trash 3 selected? y/N: ", content = { { "" } }, pos = 0, } },
      showmode = { { "-- VISUAL LINE --", "ModeMsg" } },
    })

    nf.feed_sync({
      "y<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d 1                     │~                                                |
       d 1 f 1               │~                                                |
    d 2                     │~                                                |
  ^   trash_fail.sh           │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
          ]],
      messages = {
        { content = { { "[NvimTree] trash failed: synthetic trash failure; please see :help nvim-tree.trash", "WarningMsg" } }, history = true, kind = "echomsg" },
        { content = { { "[NvimTree] trash failed: synthetic trash failure; please see :help nvim-tree.trash", "WarningMsg" } }, history = true, kind = "echomsg" }
      },
    })

    na.events_received({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/f 1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/f 1", }, },
    })

    na.path_exists("file", "/tmp/nvt_func/data/d 1/d 1 f 1")
    na.path_exists("directory", "/tmp/nvt_func/data/d 2")
    na.not_path_exists("/tmp/nvt_func/data/f 1")
  end)
end)

-- vim:colorcolumn=80
