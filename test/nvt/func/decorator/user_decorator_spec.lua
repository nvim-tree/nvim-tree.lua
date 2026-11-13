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
    data = "test/nvt/func/decorator/user_decorator_data/",
    hi_defs = {
      UDIcon1 = { fg = "#6fbbf7", },
      UDIcon2 = { fg = "#8f37e5", },
      UDIconNode = { fg = "#2a7642", },
      UDName = { fg = "#1d3edc", },
    },
  })
end)


t.describe("Decorator user", function()
  t.it("inline", function()
    n.exec_lua(function()
      require("nvim-tree").setup({
        renderer = {
          decorators = {
            "Copied",
            require("ud_inline"),
            "Cut",
          },
        },
      })
    end)

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
      "<down>",
      "x",
      "<down>",
      "c",
      "gg",
    })

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolderCL:^/tmp/nvt_func/data/..}{NvimTreeNormalCL:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{UDIconNode:N}{NvimTreeNormal: }{NvimTreeCutHL:cut_overrides_decorator}{NvimTreeNormal: }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{UDIconNode:N}{NvimTreeNormal: }{UDName:decorator_overrides_copi}{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: ud_inline.lua           }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: ud_sign_col.lua         }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/decorator_overrides_copied copied to clipboard.   |
      ]],
    })
  end)

  t.it("sign col", function()
    n.exec_lua(function()
      require("nvim-tree").setup({
        renderer = {
          decorators = {
            require("ud_sign_col"),
          },
        },
      })
    end)

    nf.feed_sync({
      ":NvimTreeOpen<CR>",
    })

    screen:expect({
      grid = [[
  {NvimTreeSignColumn:  }{NvimTreeRootFolderCL:^/tmp/nvt_func/data/..}{NvimTreeNormalCL:       }{NvimTreeWinSeparator:│}                                                 |
  {UDIcon1:1 }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: cut_overrides_decorator }{NvimTreeWinSeparator:│}{1:~                                                }|
  {UDIcon1:1 }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: decorator_overrides_copi}{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: ud_inline.lua           }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: ud_sign_col.lua         }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  :NvimTreeOpen                                                                   |
      ]],
    })
  end)
end)

-- vim:colorcolumn=80
