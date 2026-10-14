local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")
local nu = require("test.nvt.func.util")

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local it = t.it or it
---@diagnostic enable: undefined-global


--- @type test.functional.ui.screen
local screen


-- TODO test:
-- many
-- failed file and dir

---@param config nvim_tree.config
---@return test.functional.ui.screen
local function create_trash_session(config)
  screen = nf.create_session(config, nil, nil, { ext_cmdline = true, })

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.FileRemoved)
  nf.event_subscribe(Event.WillRemoveFile)
  nf.event_subscribe(Event.FolderRemoved)

  return screen
end


describe("fs.trash", function()
  it("single file buffer deleted", function()
    screen = create_trash_session({
      trash = {
        -- TODO this executes async, need to wait for completion and tree to update, maybe disable watchers
        -- cmd = "sleep 1; rm ",
        cmd = "rm ",
      }
    })

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "<CR>",
      ":NvimTreeFocus<CR>",
      "D",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Trash d1f1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "y<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..                                                         |
    d1                                                                        |
  ^  d2                                                                        |
     f1                                                                        |
~                                                                               |*19
                                                                                |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d1/d1f1")
    na.not_buf_exists("/tmp/nvt_func/data/d1/d1f1")

    na.events_received({
      { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d1/d1f1", }, },
      { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d1/d1f1", }, },
    })
  end)


  it("single dir", function()
    screen = create_trash_session({
      trash = {
        -- TODO this executes async, need to wait for completion and tree to update, maybe disable watchers
        -- cmd = "sleep 1; rm -rf ",
        cmd = "rm -rf ",
      }
    })

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "D",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Trash d1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "y<CR>",
      "gg",
      "E",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d2                      │~                                                |
       d2f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d1")

    na.events_received({
      { event_type = "FolderRemoved", payload = { folder_name = "/tmp/nvt_func/data/d1", }, },
    })
  end)


  it("invalid trash.cmd", function()
    screen = create_trash_session({
      trash = {
        cmd = "foobarbaz",
      }
    })

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "D",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Trash d1f1? y/N: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "y<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^     d1f1                  │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] trash.cmd 'foobarbaz' is not an executable.                          |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d1/d1f1")

    na.events_received({})
  end)


  it("ignore root", function()
    screen = create_trash_session({})

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "D",
    })

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d1")
    na.file_exists("/tmp/nvt_func/data/d1/d1f1")
    na.dir_exists("/tmp/nvt_func/data/d2")
    na.file_exists("/tmp/nvt_func/data/d2/d2f1")
    na.file_exists("/tmp/nvt_func/data/f1")

    na.events_received({})
  end)
end)

-- vim:colorcolumn=80
