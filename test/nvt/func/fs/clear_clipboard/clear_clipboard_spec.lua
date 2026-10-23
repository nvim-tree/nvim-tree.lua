local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


--- @type test.functional.ui.screen
local screen


t.before_each(function()
  screen = nf.create_session({
    data = "test/nvt/func/fs/clear_clipboard/data",
    screen_opts = { ext_messages = true, },
  })
end)


t.describe("fs.clear_clipboard", function()
  t.it("empty", function()
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.clear_clipboard()
    end)

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Clipboard has been emptied." } }, history = true, kind = "echomsg" }, }
    })
  end)


  t.it("many", function()
    nf.feed_sync({
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

    screen:expect({
      messages = {
        { content = { { "[NvimTree] /tmp/nvt_func/data/d1/d1f1 added to clipboard." } }, history = true, kind = "echomsg" },
        { content = { { "[NvimTree] /tmp/nvt_func/data/d1/d1f2 added to clipboard." } }, history = true, kind = "echomsg" },
        { content = { { "[NvimTree] /tmp/nvt_func/data/d2 added to clipboard." } },      history = true, kind = "echomsg" },
        { content = { { "[NvimTree] /tmp/nvt_func/data/d3 added to clipboard." } },      history = true, kind = "echomsg" },
      },
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d1f1}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCutHL:d1f2}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeCutHLCL:d3}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*15
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
]],
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      attr_ids = {},
      messages = { {
        history = true,
        kind = "echomsg",
        content = { { [[[NvimTree]
Cut
 * /tmp/nvt_func/data/d1/d1f2
 * /tmp/nvt_func/data/d3
Copy
 * /tmp/nvt_func/data/d1/d1f1
 * /tmp/nvt_func/data/d2
]], } },
      } },
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.clear_clipboard()
    end)

    screen:expect({
      attr_ids = {},
      messages = { { content = { { "[NvimTree] Clipboard has been emptied.", } }, history = true, kind = "echomsg", } },
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.print_clipboard()
    end)

    screen:expect({
      messages = { { content = { { "[NvimTree]\n\n", } }, history = true, kind = "echomsg", } },
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f2                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeFolderNameCL:d3}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*15
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  ]],
    })
  end)
end)

-- vim:colorcolumn=80
