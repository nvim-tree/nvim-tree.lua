local t = require('test.testutil')
local n = require('test.functional.testnvim')()
local Screen = require('test.functional.ui.screen')
local clear = n.clear
local command = n.command
local exec_lua = n.exec_lua

describe('example', function()
  --- @type test.functional.ui.screen
  local screen

  setup(function()
    clear({ args_rm = { '-u' } })

    -- TODO add package from the real location, not the link runtime/pack/dist/opt/nvim-tree.lua
    command('packadd nvim-tree.lua')
    screen = Screen.new(40, 20)
  end)

  before_each(function()
    -- TODO think about copying contents of an actual directory into tmp rather than copying
    local tmp = t.tmpname(false)
    assert(t.mkdir(tmp))
    t.write_file(tmp .. '/file1', 'foo', true)
    t.write_file(tmp .. '/file2', 'bar', true)
    assert(t.mkdir(tmp .. '/dir1'))

    command(':cd ' .. tmp)

    -- TODO try and use a function, not a lua string, if we have luals issues
    exec_lua([[
      require("nvim-tree").setup({
        renderer = {
          root_folder_label = false,
        },
      })
      ]])
  end)

  it('api_tree_open', function()
    exec_lua([[
      local api = require("nvim-tree.api")
      api.tree.open()
      ]])

    -- TODO use the complete set of nvim-tree HighlightGroup as test.functional.ui.screen.hl_groups
    screen:add_extra_attr_ids({
      [100] = { background = Screen.colors.Grey90, foreground = tonumber('0x8094b4') },
      [101] = { background = Screen.colors.Grey90, foreground = Screen.colors.Blue },
      [102] = { foreground = tonumber('0x8094b4') },
    })

    -- screen:snapshot_util()

    -- TODO use a grid
    screen:expect([[
        {100:^ }{21: }{101:dir1}{21:                    }│         |
        {102:  } file1                   │{1:~        }|
        {102:  } file2                   │{1:~        }|
      {1:~                             }│{1:~        }|*15
      {3:NvimTree_1 [-]                 }{2:<o Name] }|
                                              |
    ]])
  end)
end)
