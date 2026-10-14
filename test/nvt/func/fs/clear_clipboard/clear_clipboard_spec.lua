local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")
local nu = require("test.nvt.func.util")

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global


--- @type test.functional.ui.screen
local screen


before_each(function()
  screen = nf.create_session()
end)


describe("fs.clear_clipboard", function()
  it("empty", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.clear_clipboard()
    end)

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*16
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] Clipboard has been emptied.                                          |
    ]],
    })
  end)


  it("many", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<CR>",
      "<down>",
      "c",
      "<down>",
      "x",
      "<down>",
      "c",
      "<down>",
      "x",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d1f1}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCutHL:d1f2}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL: }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeCutHLCL:d3}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*7
{3:                                                                                }|
[NvimTree]                                                                      |
Cut                                                                             |
 * /tmp/nvt_func/data/d1/d1f2                                                   |
 * /tmp/nvt_func/data/d3                                                        |
Copy                                                                            |
 * /tmp/nvt_func/data/d1/d1f1                                                   |
 * /tmp/nvt_func/data/d2                                                        |
{6:Press ENTER or type command to continue}^                                         |
    ]],
    })

    nu.feed_sync({
      "<CR>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.clear_clipboard()
    end)

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f2                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeFolderNameCL:d3}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*14
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
[NvimTree] Clipboard has been emptied.                                          |
    ]],
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f2                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL: }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeFolderNameCL:d3}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*12
{3:                                                                                }|
[NvimTree]                                                                      |
                                                                                |
{6:Press ENTER or type command to continue}^                                         |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
