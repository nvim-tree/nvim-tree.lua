local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  -- don't use ext_messages as the pick window prompt is a print, not a prompt

  screen = nf.create_session({
    data = "test/nvt/func/node/open/horizontal_data",
  })
end)


t.describe("node.open.horizontal", function()
  t.it("one file window", function()
    nf.feed_sync({
      ":e f1<CR>",
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<C-x>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^f2                                               |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*8
~                             │f2                                               |
~                             │f1                                               |
~                             │~                                                |*9
NvimTree_1 [-]                 f1                                               |
:NvimTreeOpen                                                                   |
      ]],
    })
  end)


  t.it("two file windows", function()
    nf.feed_sync({
      ":e f1<CR>",
      "<C-w><C-v>",
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<C-x>",
    })

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}f1                      │f1                      |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                       }│{1:~                       }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: f2                      }{NvimTreeWinSeparator:│}{1:~                       }│{1:~                       }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                       }│{1:~                       }|*19
{NvimTreeStatusLine:NvimTree_1 [-]                 }{NvimTreeWindowPicker:           A                        B            }|
Pick window: ^                                                                   |
      ]],
    })

    nf.feed_sync({
      "b",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │f1                      │^f2                      |
     f1                      │~                       │~                       |
     f2                      │~                       │~                       |
~                             │~                       │~                       |*8
~                             │~                       │f2                      |
~                             │~                       │f1                      |
~                             │~                       │~                       |*9
NvimTree_1 [-]                 f1                       f1                      |
                                                                                |
      ]],
    })
  end)


  t.it("two file windows window_picker.enable = false", function()
    n.exec_lua(function()
      require("nvim-tree").setup({
        actions = { open_file = { window_picker = { enable = false } } },
      })
    end)

    nf.feed_sync({
      ":e f1<CR>",
      "<C-w><C-v>",
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<C-x>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^f2                      │f1                      |
     f1                      │~                       │~                       |
     f2                      │~                       │~                       |
~                             │~                       │~                       |*8
~                             │f2                      │~                       |
~                             │f1                      │~                       |
~                             │~                       │~                       |*9
NvimTree_1 [-]                 f1                       f1                      |
:NvimTreeOpen                                                                   |
      ]],
    })
  end)


  t.it("no windows", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      ":only<CR>",
      "<down><down>",
      "<C-x>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^f2                                               |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 f2                                               |
:only                                                                           |
      ]],
    })
  end)


  t.it("buffer window exists", function()
    nf.feed_sync({
      ":e f1<CR>",
      "<C-w><C-v>",
      ":e f2<CR>",
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<C-x>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^f2                      │f1                      |
     f1                      │~                       │~                       |
     f2                      │~                       │~                       |
~                             │~                       │~                       |*19
NvimTree_1 [-]                 f2                       f1                      |
:NvimTreeOpen                                                                   |
      ]],
    })
  end)
end)


t.describe("node.open.horizontal_no_picker", function()
  t.it("two file windows", function()
    nf.feed_sync({
      ":e f1<CR>",
      "<C-w><C-v>",
      ":NvimTreeOpen<CR>",
      "<down><down>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").node.open.horizontal_no_picker()
    end)

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^f2                      │f1                      |
     f1                      │~                       │~                       |
     f2                      │~                       │~                       |
~                             │~                       │~                       |*8
~                             │f2                      │~                       |
~                             │f1                      │~                       |
~                             │~                       │~                       |*9
NvimTree_1 [-]                 f1                       f1                      |
:NvimTreeOpen                                                                   |
      ]],
    })
  end)
end)

-- vim:colorcolumn=80
