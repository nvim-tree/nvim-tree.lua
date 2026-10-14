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
-- clear buffer
-- many
-- events
-- failed file and dir


describe("fs.trash", function()
  it("single file", function()
    screen = nf.create_session({
      trash = {
        -- TODO this executes async, need to wait for completion and tree to update, maybe disable watchers
        -- cmd = "sleep 1; rm ",
        cmd = "rm ",
      }
    }, nil, nil, { ext_cmdline = true, })

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
    d1                      │~                                                |
  ^  d2                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.not_path_exists("/tmp/nvt_func/data/d1/d1f1")
  end)


  it("single dir", function()
    screen = nf.create_session({
      trash = {
        -- TODO this executes async, need to wait for completion and tree to update, maybe disable watchers
        -- cmd = "sleep 1; rm -rf ",
        cmd = "rm -rf ",
      }
    }, nil, nil, { ext_cmdline = true, })

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
  end)


  it("invalid trash.cmd", function()
    screen = nf.create_session({
      trash = {
        cmd = "foobarbaz",
      }
    }, nil, nil, { ext_cmdline = true, })

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
  end)


  it("ignore root", function()
    screen = nf.create_session({}, nil, nil, nil)

    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "D",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
:NvimTreeOpen                                                                   |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d1")
    na.file_exists("/tmp/nvt_func/data/d1/d1f1")
    na.dir_exists("/tmp/nvt_func/data/d2")
    na.file_exists("/tmp/nvt_func/data/d2/d2f1")
    na.file_exists("/tmp/nvt_func/data/f1")
  end)
end)

-- vim:colorcolumn=80
