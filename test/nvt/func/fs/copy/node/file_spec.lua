local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
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
  screen = nf.create_session()

  n.exec_lua(function()
    require("nvim-tree").setup({
      actions = {
        use_system_clipboard = false,
      },
    })
  end)
end)


-- TODO system clipboard + with dummy provider, see :help clipboard

describe("single", function()
  it("file highlight", function()
    nf.unique_highlight_groups(screen)

    n.fn.setreg("1", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "c"
    )

    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("1"))

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

    screen:expect({
      unchanged = true,
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

  it("dir highlight", function()
    nf.unique_highlight_groups(screen)

    n.fn.setreg("1", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "c"
    )

    t.eq("/tmp/nvt_func/data/d2/", n.fn.getreg("1"))

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
[NvimTree] /tmp/nvt_func/data/d2 added to clipboard.                            |
    ]],
    })

    screen:expect({
      unchanged = true,
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

  it("toggle", function()
    n.fn.setreg("1", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "c"
    )

    t.eq("/tmp/nvt_func/data/f1", n.fn.getreg("1"))

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
      "c"
    )

    t.eq("", n.fn.getreg("1"))

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
end)

describe("multiple", function()
  it("dir overriding file highlight", function()
    nf.unique_highlight_groups(screen)

    n.fn.setreg("1", "foo")

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
      "c"
    )

    t.eq([[
/tmp/nvt_func/data/d1/d1f2
/tmp/nvt_func/data/d2/
/tmp/nvt_func/data/f1]], n.fn.getreg("1"))

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
       d2f1                  │~                                                |
  ^   f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*14
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] 3 nodes added to clipboard.                                          |
    ]],
    })

    screen:expect({
      unchanged = true,
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

  it("toggle", function()
    n.fn.setreg("1", "foo")

    n.feed(
      ":NvimTreeOpen<CR>",
      "<Down>",
      "c"
    )

    t.eq("/tmp/nvt_func/data/d1/", n.fn.getreg("1"))

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
      "c"
    )

    t.eq("/tmp/nvt_func/data/d2/", n.fn.getreg("1"))

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
end)

-- vim:colorcolumn=80
