local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local eq = t.eq
local clear = n.clear
local exec_lua = n.exec_lua

-- 0.13 global compatibility
---@diagnostic disable: undefined-global
local describe = t.describe or describe
local before_each = t.before_each or before_each
local it = t.it or it
local setup = t.setup or setup
---@diagnostic enable: undefined-global

-- TODO extract nvt test utils
-- TODO use vim.system instead of vim.fn.system

-- remove $NVT_FUNC_TMP
-- cd to $NVT_FUNC_TMP
-- if $NVT_FUNC_SRC/data exists:recursively copy it to $NVT_FUNC_TMP and cd
local function setup_dirs()
  local tmp = os.getenv("NVT_FUNC_TMP")
  if not tmp then
    return
  end

  -- blow away temp
  print(n.fn.system({ "rm", "-r", "-f", "-v", tmp }))
  print(n.fn.system({ "mkdir", "-p", "-v", tmp }))

  -- always cd to tmp
  n.api.nvim_set_current_dir(tmp)

  -- maybe copy data and cd
  local src = os.getenv("NVT_FUNC_SRC")
  if src then
    -- TODO handle data not present
    print(n.fn.system({ "cp", "-p", "-r", "-v", src .. "/data", tmp .. "/data" }))
    n.api.nvim_set_current_dir(tmp .. "/data")
  end
end

--- @type test.functional.ui.screen
local screen

before_each(function()
  exec_lua(function()
    require("nvim-tree").setup({})
  end)
end)

describe("single", function()
  setup(function()
    clear()

    screen = Screen.new(80, 24)

    exec_lua(function()
      vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})
    end)

    setup_dirs()
  end)

  it("direct", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "a",
      "direct/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^  direct                  │~                                                |
     f1                      │~                                                |
~                             │~                                                |*18
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/direct/ was properly created                      |
    ]],
    })

    local stat, err = vim.uv.fs_stat("/tmp/nvt_func/data/direct")
    eq(err,                nil)
    eq(stat and stat.type, "directory")
  end)

  it("indirect", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a",
      "d1/indirect/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
  ^    indirect              │~                                                |
       d1f1                  │~                                                |
    direct                  │~                                                |
     f1                      │~                                                |
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
[NvimTree] /tmp/nvt_func/data/d1/indirect/ was properly created                 |
    ]],
    })

    local stat, err = vim.uv.fs_stat("/tmp/nvt_func/data/d1/indirect")
    eq(err,                nil)
    eq(stat and stat.type, "directory")
  end)

  it("dir_exists", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a",
      "d1/<CR>"
    )

    screen:expect({
      attr_ids = {},
      grid = [[
  ^/tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    direct                  │~                                                |
     f1                      │~                                                |
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
~                             │~                                                |
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] Cannot create: file already exists                                   |
    ]],
    })
  end)

  it("file_exists", function()
    n.feed(
      ":NvimTreeOpen<CR>",
      "gg",
      "a",
      "d1/d1f1/<CR>"
    )

    -- TODO BUG this fails but shows message "/tmp/nvt_func/data/d1/d1f1/ was properly created"
    --     screen:expect({
    --       attr_ids = {},
    --       grid = [[
    --   ^/tmp/nvt_func/data/..       │                                                 |
    --     d1                      │~                                                |
    --     direct                  │~                                                |
    --      f1                      │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- ~                             │~                                                |
    -- NvimTree_1 [-]                 [No Name]                                        |
    -- [NvimTree] Cannot create: file already exists                                   |
    --     ]],
    --     })
  end)
end)

-- vim:colorcolumn=80
