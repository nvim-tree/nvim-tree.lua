local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
local n = require("test.functional.testnvim")()

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global


-- TODO BUG singe operations report "added to clipboard", not "cut to clipboard" as per bulk operations


--- @type test.functional.ui.screen
local screen


before_each(function()
  screen = nf.create_session()
end)


describe("fs.cut.node", function()
  it("single file", function()
    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "x"
    )

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
  end)


  it("single dir", function()
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "x"
    )

    t.eq("/tmp/nvt_func/data/d2/", n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^ }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalCL: }{NvimTreeCutHLCL:d2}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/d2 added to clipboard.                            |
    ]],
    })
  end)

  it("toggle one", function()
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "x"
    )

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

    n.feed(
      "x"
    )

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


  it("toggle many", function()
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<Down>",
      "x"
    )

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

    n.feed(
      "<S-v>",
      "<Down>",
      "x"
    )

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
[NvimTree] 1 nodes cut to clipboard.                                            |
    ]],
    })
  end)


  it("no system clipboard", function()
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
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "x"
    )

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


  it("single overrides copy", function()
    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "c"
    )

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

    n.feed(
      "x"
    )

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
  end)


  it("multiple overrides copy", function()
    n.fn.setreg("1", "foo")
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<down>",
      "<CR>",
      "<down>",
      "c",
      "<down>",
      "c"
    )

    t.eq("foo", n.fn.getreg("1"))
    t.eq([[
/tmp/nvt_func/data/d1/
/tmp/nvt_func/data/d2/d2f1
/tmp/nvt_func/data/f1]], n.fn.getreg("+"))

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d2f1}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*16
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    n.feed(
      "gg",
      "<down>",
      "<S-v>",
      "<down>",
      "<down>",
      "<down>",
      "<down>",
      "x"
    )

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeCutHL:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeCutHL:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCopiedHL:d2f1}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCutHL:f1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCutHLCL:f2}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*16
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
[NvimTree] 4 nodes cut to clipboard.                                            |
    ]],
    })

    t.eq("foo", n.fn.getreg("1"))
    t.eq([[
/tmp/nvt_func/data/d1/
/tmp/nvt_func/data/d2/
/tmp/nvt_func/data/f1
/tmp/nvt_func/data/f2]], n.fn.getreg("+"))
  end)


  it("dir overrides file", function()
    n.fn.setreg("+", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "E",
      "<Down>",
      "<Down>",
      "<Down>",
      "<S-v>",
      "<Down>",
      "<Down>",
      "<Down>",
      "x"
    )

    t.eq([[
/tmp/nvt_func/data/d1/d1f2
/tmp/nvt_func/data/d2/
/tmp/nvt_func/data/f1]], n.fn.getreg("+"))

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: }{NvimTreeCutHL:d1f2}{NvimTreeNormal:                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeCutHL:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d2f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCutHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*14
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] 3 nodes cut to clipboard.                                            |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
