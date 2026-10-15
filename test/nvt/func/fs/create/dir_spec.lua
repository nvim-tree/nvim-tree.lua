local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")
local nu = require("test.nvt.func.util")

-- 0.12 global compatibility
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each ---@diagnostic disable-line: inject-field, undefined-global

--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session()

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.FolderCreated)
end)


t.describe("fs.create dir", function()
  t.it("single direct", function()
    nu.feed_sync({
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

    na.dir_exists("/tmp/nvt_func/data/direct")

    na.events_received({
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct/", }, },
    })
  end)


  t.it("single indirect", function()
    nu.feed_sync({
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

    na.dir_exists("/tmp/nvt_func/data/d1/indirect")

    na.events_received({
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect/", }, },
    })
  end)


  t.it("api single indirect", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    -- schedule this as it blocks on vim.ui.input
    n.exec_lua(function()
      vim.schedule(require("nvim-tree.api").fs.create)
    end)

    -- wait for the input
    n.poke_eventloop()

    nu.feed_sync({
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

    na.dir_exists("/tmp/nvt_func/data/d1/indirect")

    na.events_received({
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect/", }, },
    })
  end)


  t.it("multiple direct", function()
    nu.feed_sync({
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

    na.dir_exists("/tmp/nvt_func/data/direct1")
    na.dir_exists("/tmp/nvt_func/data/direct1/direct2")

    na.events_received({
      -- BUG this should be "/tmp/nvt_func/data/direct1/"
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct1/direct2/", }, },
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct1/direct2/", }, },
    })
  end)


  t.it("multiple indirect", function()
    nu.feed_sync({
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

    na.dir_exists("/tmp/nvt_func/data/d1/indirect1")
    na.dir_exists("/tmp/nvt_func/data/d1/indirect1/indirect2")

    na.events_received({
      -- BUG this should be "/tmp/nvt_func/data/d1/indirect1/"
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect1/indirect2/", }, },
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect1/indirect2/", }, },
    })
  end)


  t.it("fails when file exists", function()
    nu.feed_sync({
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
    nu.feed_sync({
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
    nu.feed_sync({
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
    nu.feed_sync({
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

-- vim:colorcolumn=80
