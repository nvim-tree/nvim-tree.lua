local t = require("test.testutil")
local nf = require("test.functional.nvt.fixtures")
local nt = require("test.functional.nvt.utils")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local clear = n.clear
local exec_lua = n.exec_lua

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
local setup = t.setup or setup
---@diagnostic enable: undefined-global

describe("api_tree_open", function()
  --- @type test.functional.ui.screen
  local screen

  setup(function()
    clear()

    screen = Screen.new(80, 24)

    exec_lua(function()
      vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})
    end)

    n.api.nvim_set_current_dir(nf.create_test_dir(n.fn.system))
  end)

  before_each(function()
    exec_lua(function()
      require("nvim-tree").setup({})
    end)

    screen:add_extra_attr_ids(nt.simple_attr_ids())
  end)

  it("populated_unfocussed_text_only", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("<c-w><c-w>")

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │^                                                 |
    dir1                    │~                                                |
    dir2                    │~                                                |
     file1                   │~                                                |
     file2                   │~                                                |
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
~                             │~                                                |
~                             │~                                                |
~                             │~                                                |
NvimTree_1 [-]                 [No Name]                                        |
                                                                                |
    ]],
    })
  end)

  it("populated_unfocussed_hl_attrs", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    -- TODO BUG NvimTreeFolderArrowClosed is always set by Padding:get_arrows, it should only be set for DirectoryNode
    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolderCL:^/tmp/nvt_func/data/..}{NvimTreeNormalCL:       }{NvimTreeWinSeparator:│}                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:dir1}{NvimTreeNormal:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:dir2}{NvimTreeNormal:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: file1                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: file2                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
{NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
                                                                                |
    ]],
    })
  end)

  it("populated_unfocussed_hl_attrs", function()
    exec_lua(function()
      require("nvim-tree.api").tree.open()
    end)

    n.feed("<down>")
    n.feed("<c-w><c-w>")

    screen:expect({
      grid = [[
{NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormalNC:       }{NvimTreeWinSeparator:│}^                                                 |
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL: }{NvimTreeClosedFolderIconCL:}{NvimTreeNormalNCCL: }{NvimTreeFolderNameCL:dir1}{NvimTreeNormalNCCL:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormalNC: }{NvimTreeFolderName:dir2}{NvimTreeNormalNC:                    }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormalNC: file1                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormalNC: file2                   }{NvimTreeWinSeparator:│}{1:~                                                }|
{NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
{NvimTreeStatusLineNC:NvimTree_1 [-]                 }{3:[No Name]                                        }|
                                                                                |
    ]],
    })
  end)
end)

-- vim:colorcolumn=80
