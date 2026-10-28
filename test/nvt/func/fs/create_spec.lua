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
    data = "test/nvt/func/fs/create_data",
    screen_opts = { ext_cmdline = true },
  })
end)


t.describe("fs.create dir", function()
  t.before_each(function()
    local Event = require("nvim-tree._meta.api.events").Event
    nf.event_subscribe(Event.FolderCreated)
  end)

  t.it("single direct", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "direct/<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^  direct                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/direct/ was properly created                      |
    ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/direct")

    na.events_received({
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct/", }, },
    })
  end)


  t.it("single indirect", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect/<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^    indirect              │~                                                |
       d1f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/indirect/ was properly created                 |
    ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d1/indirect")

    na.events_received({
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect/", }, },
    })
  end)


  t.it("api single indirect", function()
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
      "d1/indirect/<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^    indirect              │~                                                |
       d1f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/indirect/ was properly created                 |
    ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d1/indirect")

    na.events_received({
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect/", }, },
    })
  end)


  t.it("multiple direct", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "direct1/direct2/<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    direct1                 │~                                                |
  ^    direct2               │~                                                |
     f1                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/direct1/direct2/ was properly created             |
    ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/direct1")
    na.path_exists("directory", "/tmp/nvt_func/data/direct1/direct2")

    na.events_received({
      -- BUG this should be "/tmp/nvt_func/data/direct1/"
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct1/direct2/", }, },
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct1/direct2/", }, },
    })
  end)


  t.it("multiple indirect", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect1/indirect2/<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
      indirect1             │~                                                |
  ^      indirect2           │~                                                |
       d1f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*16
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/indirect1/indirect2/ was properly created      |
    ]],
    })

    na.path_exists("directory", "/tmp/nvt_func/data/d1/indirect1")
    na.path_exists("directory", "/tmp/nvt_func/data/d1/indirect1/indirect2")

    na.events_received({
      -- BUG this should be "/tmp/nvt_func/data/d1/indirect1/"
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect1/indirect2/", }, },
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect1/indirect2/", }, },
    })
  end)


  t.it("fails when file exists", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "d1/<CR>",
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

    na.events_received({})
  end)


  t.it("fails when file exists", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "d1/d1f1/<CR>",
    })

    -- BUG this fails but shows message "/tmp/nvt_func/data/d1/d1f1/ was properly created" and focuses the file
    -- add similar test for multiple dirs when fixed
    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^     d1f1                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1/d1f1/ was properly created                     |
        ]],
    })

    na.events_received({})
  end)


  t.it("fails on invalid path", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "a",
      "<C-U>",
      "/foo/bar<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] Could not create folder /foo                                         |
        ]],
    })

    na.events_received({})
  end)


  t.it("fails when dir exists", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "a",
      "<CR>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
  ^  d1                      │~                                                |
     f1                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)
end)



t.describe("fs.create file", function()
  t.before_each(function()
    local Event = require("nvim-tree._meta.api.events").Event
    nf.event_subscribe(Event.FileCreated)
    nf.event_subscribe(Event.WillCreateFile)
    nf.event_subscribe(Event.FolderCreated)
  end)


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

    na.path_exists("file", "/tmp/nvt_func/data/direct")

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

    na.path_exists("file", "/tmp/nvt_func/data/d1/indirect")

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

    na.path_exists("file", "/tmp/nvt_func/data/d1/indirect")

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

    na.path_exists("file", "/tmp/nvt_func/data/f1")

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

    na.path_exists("directory", "/tmp/nvt_func/data/d1")

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

    na.path_exists("directory", "/tmp/nvt_func/data/d1")

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


t.describe("fs.create prompt", function()
  t.it("tree focused", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "a",
    })

    screen:expect({
      attr_ids = {},
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
      attr_ids = {},
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
      attr_ids = {},
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
