local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")

-- 0.12 global compatibility
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each ---@diagnostic disable-line: inject-field, undefined-global

--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session()

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.FileCreated)
  nf.event_subscribe(Event.WillCreateFile)
  nf.event_subscribe(Event.FolderCreated)
end)


t.describe("fs.create file", function()
  t.it("direct", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "direct<CR>",
    })

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


  t.it("indirect", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect<CR>",
    })

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


  t.it("api indirect", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    -- schedule this as it blocks on vim.ui.input
    n.exec_lua(function()
      vim.schedule(require("nvim-tree.api").fs.create)
    end)

    -- wait for the input
    n.poke_eventloop()

    nf.feed_sync({
      "d1/indirect<CR>",
    })

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


  t.it("fails when file exists", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "f1<CR>",
    })

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


  t.it("fails when dir exists", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "d1<CR>",
    })

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


  t.it("indirect creates dirs", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "newdir/newfile<CR>",
    })

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
      -- BUG this should be "/tmp/nvt_func/data/newdir/"
      { event_type = "FolderCreated",  payload = { folder_name = "/tmp/nvt_func/data/newdir/newfile", }, },
      { event_type = "WillCreateFile", payload = { fname = "/tmp/nvt_func/data/newdir/newfile", }, },
      { event_type = "FileCreated",    payload = { fname = "/tmp/nvt_func/data/newdir/newfile", }, },
    })
  end)


  t.it("fails on invalid path", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "<C-U>",
    })

    n.feed(
      "/foo<CR>"
    )

    -- BUG this fails but shows message "/foo was properly created"
    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
                                                                                |
[NvimTree] Couldn't create file /foo                                            |
[NvimTree] /foo was properly created                                            |
Press ENTER or type command to continue^                                         |
    ]],
    })

    n.feed(
      "<CR>"
    )

    na.events_received({
      { event_type = "WillCreateFile", payload = { fname = "/foo", }, },
    })
  end)
end)

-- vim:colorcolumn=80
