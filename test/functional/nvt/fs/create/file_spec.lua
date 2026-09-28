local t = require("test.testutil")
local nf = require("test.functional.nvt.fixtures")
local na = require("test.functional.nvt.asserts")
local n = require("test.functional.testnvim")()

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global

--- @type test.functional.ui.screen
local screen


before_each(function()
  screen = nf.create_session({ ext_cmdline = true })

  n.exec_lua(function()
    require("nvim-tree").setup({})
  end)

  nf.event_subscribe("FileCreated")
  nf.event_subscribe("WillCreateFile")
  nf.event_subscribe("FolderCreated")
end)


describe("prompt", function()
  it("ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
    })
  end)
end)


describe("single file", function()
  it("direct ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "direct<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^   direct                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/direct was properly created                       |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/direct")

    na.events_received({
      { event_type = "WillCreateFile", payload = { fname = "/tmp/nvt_func/data/direct", }, },
      { event_type = "FileCreated",    payload = { fname = "/tmp/nvt_func/data/direct", }, },
    })
  end)


  it("indirect ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
  ^     indirect              │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/indirect was properly created                  |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d1/indirect")

    na.events_received({
      { event_type = "WillCreateFile", payload = { fname = "/tmp/nvt_func/data/d1/indirect", }, },
      { event_type = "FileCreated",    payload = { fname = "/tmp/nvt_func/data/d1/indirect", }, },
    })
  end)


  it("existing file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "f1<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] Cannot create: file already exists                                   |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/f1")

    na.events_received({})
  end)


  it("existing dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] Cannot create: file already exists                                   |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d1")

    na.events_received({})
  end)


  it("nested dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "newdir/newfile<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    newdir                  │~                                                |
  ^     newfile               │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/newdir/newfile was properly created               |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d1")

    na.events_received({
      -- TODO BUG this should be "/tmp/nvt_func/data/newdir/"
      { event_type = "FolderCreated",  payload = { folder_name = "/tmp/nvt_func/data/newdir/newfile", }, },
      { event_type = "WillCreateFile", payload = { fname = "/tmp/nvt_func/data/newdir/newfile", }, },
      { event_type = "FileCreated",    payload = { fname = "/tmp/nvt_func/data/newdir/newfile", }, },
    })
  end)


  it("invalid path", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "<C-U>",
      "/foo<CR>"
    )

    -- TODO BUG this fails but shows message "/foo was properly created"

    na.events_received({
      { event_type = "WillCreateFile", payload = { fname = "/foo", }, },
    })
  end)
end)

-- vim:colorcolumn=80
