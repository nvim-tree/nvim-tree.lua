local t = require("test.testutil")
local nf = require("test.nvt.func.fixtures")
local na = require("test.nvt.func.asserts")
local nu = require("test.nvt.func.util")

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
---@diagnostic enable: undefined-global

--- @type test.functional.ui.screen
local screen


-- common copy/paste codepaths are tested here except for API


before_each(function()
  screen = nf.create_session(nil, nil, nil, { ext_cmdline = true })
end)


describe("fs.paste.node copied", function()
  it("single file", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down><down>",
      "c",
      "<up>",
      "p",
    })

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


  it("multiple files", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down><down><down>",
      "<S-v>",
      "<down>",
      "c",
      "<up>",
      "<up>",
      "p",
    })

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
       f1                    │~                                                |
  ^     f2                    │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*13
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] 2 nodes added to clipboard.                                          |
        ]],
    })

    na.file_exists("/tmp/nvt_func/data/f1")
    na.file_exists("/tmp/nvt_func/data/f2")
    na.file_exists("/tmp/nvt_func/data/d3/f1")
    na.file_exists("/tmp/nvt_func/data/d3/f2")
  end)


  it("single dir", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<down>",
      "p",
      "<CR>",
    })

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^    d1                    │~                                                |
         d1f1                │~                                                |
         d1f2                │~                                                |
      d3                    │~                                                |
       f2                    │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*11
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
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    nu.feed_sync({
      "_copy<CR>",
      "<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^  d1_copy                 │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*13
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
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    nu.feed_sync({
      "<Esc>",
    })

    screen:expect({
      cmdline = { { abort = true } },
    })

    nu.feed_sync({
      "gg",
      "E",
    })

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
      d3                    │~                                                |
         d3f1                │~                                                |
       f2                    │~                                                |
    d3                      │~                                                |
       d3f1                  │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*10
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)


  it("single dir conflict second conflict overwrite", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    nu.feed_sync({
      "<BS>2<CR>"
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2 ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "y<CR>",
    })

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
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    nu.feed_sync({
      "<BS>2<CR>",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2 ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "n<CR>",
      "gg",
      "E",
    })

    screen:expect({
      cmdline = { { abort = true } },
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolderCL:^/tmp/nvt_func/data/..}{NvimTreeNormalCL:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d1f2                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d3}{NvimTreeNormal:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:    }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d3f1                }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                    }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowOpen: }{NvimTreeOpenedFolderIcon:}{NvimTreeNormal: }{NvimTreeOpenedFolderName:d3}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeIndentMarker:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: d3f1                  }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f1                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*10
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
                                                                                  |
    ]],
    })
  end)


  it("single dir conflict second conflict resolved", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<up>",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d1" } }, pos = 21, } },
    })

    nu.feed_sync({
      "<BS>2<CR>",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2 ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "R<CR>",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Rename to ", content = { { "/tmp/nvt_func/data/d2" } }, pos = 21, } },
    })

    nu.feed_sync({
      "<BS>1_copy<CR>",
      "<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^  d1_copy                 │~                                                |
       d1f1                  │~                                                |
       d1f2                  │~                                                |
    d2                      │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*13
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)


  it("multiple", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "c",
      "<down><down><down>",
      "c",
      "<up><up>",
      "p",
      "<up><up>",
      "<CR>",
    })

    screen:expect({
      cmdline = {},
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^    d1                    │~                                                |
         d1f1                │~                                                |
         d1f2                │~                                                |
      d3                    │~                                                |
       f1                    │~                                                |
       f2                    │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*10
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d2/f1")
    na.dir_exists("/tmp/nvt_func/data/d2/d3")
    na.file_exists("/tmp/nvt_func/data/d2/d3/d3f1")
  end)


  it("multiple conflict no rename", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<s-v>",
      "G",
      "c",
      "<up><up><up>",
      "c",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "2 file(s) already exist. R(ename suffix)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "n<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
      d1                    │~                                                |
      d3                    │~                                                |
  ^     f1                    │~                                                |
       f2                    │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*12
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.file_exists("/tmp/nvt_func/data/d2/f1")
    na.file_exists("/tmp/nvt_func/data/d2/f2")
    na.dir_exists("/tmp/nvt_func/data/d2/d3")
    na.file_exists("/tmp/nvt_func/data/d2/d3/d3f1")
  end)


  it("multiple conflict rename suffix", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<s-v>",
      "G",
      "c",
      "<up><up><up>",
      "c",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "2 file(s) already exist. R(ename suffix)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "r<CR>",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Suffix: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      ".renamed<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
      d1                    │~                                                |
      d3                    │~                                                |
      d3.renamed            │~                                                |
       f1                    │~                                                |
       f2                    │~                                                |
  ^     f2.renamed            │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*10
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.dir_exists("/tmp/nvt_func/data/d2/d3")
    na.file_exists("/tmp/nvt_func/data/d2/f1")
    na.file_exists("/tmp/nvt_func/data/d2/f2")

    na.file_exists("/tmp/nvt_func/data/d2/f2.renamed")
    na.dir_exists("/tmp/nvt_func/data/d2/d3.renamed")
    na.file_exists("/tmp/nvt_func/data/d2/d3.renamed/d3f1")
  end)


  it("multiple conflict rename cancel", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<s-v>",
      "G",
      "c",
      "<up><up><up>",
      "c",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "2 file(s) already exist. R(ename suffix)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "<CR>",
      "<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
      d1                    │~                                                |
      d3                    │~                                                |
  ^     f1                    │~                                                |
       f2                    │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*12
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.dir_exists("/tmp/nvt_func/data/d2/d3")
    na.file_exists("/tmp/nvt_func/data/d2/d3/d3f1")
    na.file_exists("/tmp/nvt_func/data/d2/f1")
    na.file_exists("/tmp/nvt_func/data/d2/f2")
  end)


  it("multiple conflict rename second conflict", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down><down>",
      "a",
      "f2.renamed<CR>",
    })

    na.file_exists("/tmp/nvt_func/data/d2/f2.renamed")

    nu.feed_sync({
      "W",
      "gg",
      "<down>",
      "<s-v>",
      "G",
      "c",
      "<up><up><up>",
      "c",
      "p",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "2 file(s) already exist. R(ename suffix)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "<CR>",
      ".renamed<CR>",
    })

    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "Overwrite /tmp/nvt_func/data/d2/f2.renamed ? R(ename)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "<CR>",
      ".again<CR>",
    })


    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
      d1                    │~                                                |
      d3                    │~                                                |
      d3.renamed            │~                                                |
       f1                    │~                                                |
       f2                    │~                                                |
       f2.renamed            │~                                                |
  ^     f2.renamed.again      │~                                                |
    d3                      │~                                                |
     f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*9
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
--
    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.dir_exists("/tmp/nvt_func/data/d2/d3")
    na.file_exists("/tmp/nvt_func/data/d2/f1")
    na.file_exists("/tmp/nvt_func/data/d2/f2")

    na.file_exists("/tmp/nvt_func/data/d2/f2.renamed")
    na.file_exists("/tmp/nvt_func/data/d2/f2.renamed.again")
    na.dir_exists("/tmp/nvt_func/data/d2/d3.renamed")
    na.file_exists("/tmp/nvt_func/data/d2/d3.renamed/d3f1")
  end)


  it("multiple conflict overwrite", function()
    nu.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "<s-v>",
      "G",
      "c",
      "<up><up><up>",
      "c",
      "p",
    })

    -- BUG: this should read as per single prompt: "2 file(s) already exist. R(ename suffix)/y/n: "
    screen:expect({
      mode = "cmdline_normal",
      cmdline = { { prompt = "2 file(s) already exist. R(ename suffix)/y/n: ", content = { { "" } }, pos = 0, } },
    })

    nu.feed_sync({
      "y<CR>",
    })

    screen:expect({
      cmdline = { { abort = true } },
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
      d1                    │~                                                |
      d3                    │~                                                |
       f1                    │~                                                |
       f2                    │~                                                |
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
                                                                                |
[NvimTree] Could not copy /tmp/nvt_func/data/d3 - EEXIST: file already exists: /|
tmp/nvt_func/data/d2/d3                                                         |
Press ENTER or type command to continue^                                         |
    ]],
    })

    na.dir_exists("/tmp/nvt_func/data/d2/d1")
    na.dir_exists("/tmp/nvt_func/data/d2/d3")
    na.file_exists("/tmp/nvt_func/data/d2/f1")
    na.file_exists("/tmp/nvt_func/data/d2/f2")
  end)
end)

-- vim:colorcolumn=80
