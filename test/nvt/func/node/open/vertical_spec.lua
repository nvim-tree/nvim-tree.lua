local t = require("test.testutil")
require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


-- tests only the base case, more comprehensive testing is done during horizontal_spec


t.before_each(function()
  -- don't use ext_messages as the pick window prompt is a print, not a prompt

  screen = nf.create_session({
    data = "test/nvt/func/node/open/horizontal_data",
  })
end)


t.describe("node.open.vertical", function()
  t.it("two file windows", function()
    nf.feed_sync({
      ":e f1<CR>",
      "<C-w><C-s>",
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "<C-v>",
    })

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}f1                                               |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*8
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{NvimTreeWindowPicker:                        A                        }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}f1                                               |
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*9
{NvimTreeStatusLine:NvimTree_1 [-]                 }{NvimTreeWindowPicker:                        B                        }|
Pick window: ^                                                                   |
      ]],
    })

    nf.feed_sync({
      "b",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │f1                                               |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*8
~                             │f1                                               |
~                             │^f2                      │f1                      |
~                             │~                       │~                       |*9
NvimTree_1 [-]                 f2                       f1                      |
                                                                                |
      ]],
    })
  end)


  t.it("no windows", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      ":only<CR>",
      "<down>",
      "<C-v>",
    })

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^f1                                               |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*19
NvimTree_1 [-]                 f1                                               |
:only                                                                           |
      ]],
    })
  end)
end)

-- vim:colorcolumn=80
