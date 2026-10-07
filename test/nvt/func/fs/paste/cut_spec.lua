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


-- common copy/paste codepaths are tested in copied_spec.lua except for API


before_each(function()
  screen = nf.create_session(nil, nil, nil, { ext_cmdline = true, })

  local Event = require("nvim-tree._meta.api.events").Event
  nf.event_subscribe(Event.NodeRenamed)
end)


describe("fs.paste.node cut", function()
  it("single dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "x",
      "<down>",
      "p",
      "E"
    )

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d2                      │~                                                |
  ^    d1                    │~                                                |
         d1f1                │~                                                |
         d1f2                │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*13
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1 added to clipboard.                            |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f2")

    na.not_path_exists("/tmp/nvt_func/data/d1")

    na.events_received({ {
      event_type = "NodeRenamed",
      payload = {
        old_name = "/tmp/nvt_func/data/d1",
        new_name = "/tmp/nvt_func/data/d2/d1",
      },
    }, })
  end)


  it("single file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "<down>",
      "x",
      "<CR>",
      "<C-W><C-W>",
      "<up>",
      "p"
    )

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │f1                                               |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
  ^     f1                    │~                                                |
     f2                      │~                                                |
~                             │~                                                |*15
NvimTree_1 [-]                 /tmp/nvt_func/data/d3/f1                         |
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d3/f1")

    na.not_path_exists("/tmp/nvt_func/data/f1")

    na.events_received({ {
      event_type = "NodeRenamed",
      payload = {
        old_name = "/tmp/nvt_func/data/f1",
        new_name = "/tmp/nvt_func/data/d3/f1",
      },
    }, })

    t.eq(true,
      vim.tbl_contains(n.api.nvim_list_bufs(),
        function(buf)
          return n.api.nvim_buf_get_name(buf) == "/tmp/nvt_func/data/d3/f1" and n.api.nvim_buf_is_loaded(buf)
        end, { predicate = true }
      ),
      "buffer for /tmp/nvt_func/data/d3/f1 present and loaded"
    )
  end)


  it("api clipboard", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "x",
      "<down>"
    )

    n.exec_lua(function()
      require("nvim-tree.api").fs.paste()
    end)

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f2")

    na.not_path_exists("/tmp/nvt_func/data/d1")

    na.events_received({ {
      event_type = "NodeRenamed",
      payload = {
        old_name = "/tmp/nvt_func/data/d1",
        new_name = "/tmp/nvt_func/data/d2/d1",
      },
    }, })
  end)


  it("api node under cursor", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "x",
      "<down>"
    )

    n.exec_lua(function()
      require("nvim-tree.api").fs.paste()
    end)

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d2                      │~                                                |
  ^    d1                    │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*15
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1 added to clipboard.                            |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f2")

    na.not_path_exists("/tmp/nvt_func/data/d1")

    na.events_received({ {
      event_type = "NodeRenamed",
      payload = {
        old_name = "/tmp/nvt_func/data/d1",
        new_name = "/tmp/nvt_func/data/d2/d1",
      },
    }, })
  end)
end)

-- vim:colorcolumn=80
