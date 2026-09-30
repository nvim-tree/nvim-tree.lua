local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")
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

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.FolderCreated)
end)


describe("prompt", function()
  it("tree focused", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<Down>",
      "a"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })
  end)


  it("tree not focused", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<Down>",
      "<c-w><c-w>",
      ":lua require('nvim-tree.api').fs.create()<CR>"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/d1/" } }, pos = 22, } },
    })
  end)
end)


describe("existing", function()
  it("nop", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<Down>",
      "a",
      "<CR>"
    )

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


describe("cancelled", function()
  it("nop", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "foo",
      "<Esc>"
    )

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


describe("single dir", function()
  it("direct ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "direct/<CR>"
    )

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


  it("indirect ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect/<CR>"
    )

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


  it("existing dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1/<CR>"
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

    na.events_received({})
  end)


  it("existing file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1/d1f1/<CR>"
    )

    -- TODO BUG this fails but shows message "/tmp/nvt_func/data/d1/d1f1/ was properly created" and focuses the file
    -- TODO add similar test for multiple dirs when fixed
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


  it("invalid path", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "<C-U>",
      "/foo/bar<CR>"
    )

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
end)


describe("multiple dirs", function()
  it("direct ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "direct1/direct2/<CR>"
    )

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
      -- TODO BUG this should be "/tmp/nvt_func/data/direct1/"
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct1/direct2/", }, },
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/direct1/direct2/", }, },
    })
  end)


  it("indirect ok", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "d1/indirect1/indirect2/<CR>"
    )

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
      -- TODO BUG this should be "/tmp/nvt_func/data/d1/indirect1/"
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect1/indirect2/", }, },
      { event_type = "FolderCreated", payload = { folder_name = "/tmp/nvt_func/data/d1/indirect1/indirect2/", }, },
    })
  end)
end)

-- vim:colorcolumn=80
