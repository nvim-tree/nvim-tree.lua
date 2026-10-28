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
    data = "test/nvt/func/fs/copy/node_data",
  })
end)


t.describe("fs.copy.node", function()
  t.it("single file", function()
    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "c",
    })

    t.eq("foo",                   n.fn.getreg("1"))
    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })
  end)


  t.it("api single file", function()
    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
    })

    n.exec_lua(function()
      require("nvim-tree.api").fs.copy.node()
    end)

    t.eq("foo",                   n.fn.getreg("1"))
    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })
  end)

  t.it("single dir", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "c",
    })

    t.eq("/tmp/nvt_func/data/d2/", n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:d2}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/d2 added to clipboard.                            |
    ]],
    })
  end)


  t.it("toggle one", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "c",
    })

    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^   f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    nf.feed_sync({
      "c",
    })

    t.eq("", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^   f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/f1 removed from clipboard.                        |
    ]],
    })
  end)


  t.it("toggle many", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<Down>",
      "c",
    })

    t.eq("/tmp/nvt_func/data/d1/", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
  ^  d1                      │~                                                |
    d2                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1 added to clipboard.                            |
    ]],
    })

    nf.feed_sync({
      "<S-v>",
      "<Down>",
      "c",
    })

    t.eq("/tmp/nvt_func/data/d2/", n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^  d2                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] 1 nodes added to clipboard.                                          |
    ]],
    })
  end)


  t.it("no system clipboard", function()
    n.exec_lua(function()
      require("nvim-tree").setup({
        actions = {
          use_system_clipboard = false,
        },
      })
    end)

    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")
    --
    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "c",
    })

    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("1"))
    t.eq("foo",                   n.fn.getreg("+"))

    screen:expect({
      attr_ids = {},
      grid = [[
      /tmp/nvt_func/data/..       │                                                 |
        d1                      │~                                                |
        d2                      │~                                                |
      ^   f1                      │~                                                |
         f2                      │~                                                |
    ~                             │~                                                |*17
    NvimTree_1 [-]                 [No Name]                                        |
    [NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
        ]],
    })
  end)


  t.it("overrides cut", function()
    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down>",
      "x",
    })

    t.eq("foo",                   n.fn.getreg("1"))
    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCutHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    nf.feed_sync({
      "c",
    })

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })
  end)


  t.it("dir overrides file", function()
    n.fn.setreg("+", "foo")

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "E",
      "<down><down><down>",
      "<S-v>",
      "<down><down><down>",
      "c",
    })

    t.eq([[
/tmp/nvt_func/data/d1/d1f2
/tmp/nvt_func/data/d2/
/tmp/nvt_func/data/f1]], n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d1f2}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d2f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*14
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] 3 nodes added to clipboard.                                          |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
