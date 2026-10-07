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
  screen = nf.create_session(nil, nil, nil, { ext_cmdline = true })
end)

-- common copy/paste codepaths are tested here except for API

-- TODO multiple, needs same conflict checking as single, as the codepaths in Clipboard:resolve_conflicts are different

-- TODO partial partition


describe("fs.paste.node copied", function()
  it("single file", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "<down>",
      "<down>",
      "<down>",
      "c",
      "<up>",
      "p"
    )

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
  ^     f1                    │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*14
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/f1")
    na.file_exists("/tmp/nvt_func/data/d3/f1")
  end)


  it("single dir", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<down>",
      "p",
      "gg",
      "E"
    )

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
      d1                    │~                                                |
         d1f1                │~                                                |
         d1f2                │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*9
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/d1 added to clipboard.                            |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f1")
    na.file_exists("/tmp/nvt_func/data/d2/d1/d1f2")

    na.dir_exists("/tmp/nvt_func/data/d1")
  end)


  it("single dir conflict resolved", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    n.feed(
      "_copy<CR>",
      "gg",
      "E"
    )

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d1_copy                 │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*9
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d1")
    na.file_exists("/tmp/nvt_func/data/d1/d1f1")
    na.file_exists("/tmp/nvt_func/data/d1/d1f2")

    na.dir_exists("/tmp/nvt_func/data/d1_copy")
    na.file_exists("/tmp/nvt_func/data/d1_copy/d1f1")
    na.file_exists("/tmp/nvt_func/data/d1_copy/d1f1")
  end)


  it("single dir conflict cancelled", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    n.feed(
      "<Esc>"
    )

    screen:expect({
      cmdline = { { abort = true } },
    })

    n.feed(
      "gg",
      "E"
    )

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*12
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)


  it("single dir conflict second conflict overwrite", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    n.feed(
      "<BS>2<CR>"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2 ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    n.feed(
      "y<CR>"
    )

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
                                                                                |
[NvimTree] Could not copy /tmp/nvt_func/data/d1 - EEXIST: file already exists: /|
tmp/nvt_func/data/d2                                                            |
Press ENTER or type command to continue^                                         |
    ]],
    })
  end)


  it("single dir conflict second conflict cancel", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    n.feed(
      "<BS>2<CR>"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2 ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    n.feed(
      "n<CR>",
      "gg",
      "E"
    )

    screen:expect({
      cmdline = { { abort = true } },
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolderCL:^/tmp/nvt_func/data/..}{NvimTreeNormalCL:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f2                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d2f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d3}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d3f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*12
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
                                                                                  |
    ]],
    })
  end)


  it("single dir conflict second conflict resolved", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    n.feed(
      "<BS>2<CR>"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2 ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    n.feed(
      "R<CR>"
    )

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d2" } }, pos = 21, } },
    })

    n.feed(
      "<BS>1_copy<CR>",
      "gg",
      "E"
    )

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d1_copy                 │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
       d2f1                  │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*9
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
