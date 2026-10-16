local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")


---Globals used within test session context, noted in this test context only for type definition
---@type boolean
NVT_FUNCTEST_CONTEXT = true
---@type nvt.functest.event[]
NVT_FUNCTEST_EVENTS = {}
---@type string[]
NVT_FUNCTEST_CLIPBOARD_LINES = {}


local M = {}

---Create /tmp/nvt_func or /tmp/nvt_func/data if present
---Change running instance's directory to above
local function setup_cwd()
  ---Return the value of an environment variable, asserting presence
  ---return @string
  local function env(var)
    local val = os.getenv(var)
    assert(val, "$" .. var .. " not set")
    return val
  end

  ---Execute vim.system and waits
  ---Assers RC=0 only for nvim > 0.12
  ---@param cmd string[] Command to execute
  local function sys(cmd)
    if vim.fn and vim.fn.has("nvim-0.13") == 1 then
      local out = vim.system(cmd):wait()
      assert(out.code == 0, vim.inspect(out))
    else
      -- vim.system and n.system are not available for neovim 0.12 func tests
      -- this will fail silently
      n.fn.system(cmd)
    end
  end

  local dir_cwd, dir_test = env("NVT_FUNC_DIR_CWD"), env("NVT_FUNC_DIR_TEST")

  -- always blow away and recreate the cwd of the test instance
  sys({ "rm", "-rf", dir_cwd })
  sys({ "mkdir", "-p", dir_cwd })

  -- if data is present, recursively copy it and use that as cwd
  local dir_test_data = dir_test .. "/data"
  if vim.uv.fs_stat(dir_test_data) then
    sys({ "cp", "-p", "-r", dir_test_data, dir_cwd })
    dir_cwd = dir_cwd .. "/data"
  end

  -- set the cwd of the running test instance
  n.api.nvim_set_current_dir(dir_cwd)
end

---Create a new neovim functest session with
---- nvim-tree.lua package added
---- fresh test data directory created and cd'd into
---- nvim-tree setup called
---- nvim-tree HL attr_ids added
---- dummy clipboard setup
---@param config? nvim_tree.config passed to nvim-tree.setup
---@param width? integer default 80
---@param height? integer default 24
---@param options? test.functional.ui.screen.Opts
---@return test.functional.ui.screen
function M.create_session(config, width, height, options)
  n.clear()

  local screen = Screen.new(width or 80, height or 24, options)

  -- add the nvim-tree package and setup globals
  n.exec_lua(function()
    vim.opt.packpath:append(os.getenv("NVT_FUNC_PACKPATH") or "")
    vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})

    NVT_FUNCTEST_CONTEXT = true
    NVT_FUNCTEST_EVENTS = {}
    NVT_FUNCTEST_CLIPBOARD_LINES = {}
  end)

  -- create the test instance cwd and change directory to it
  setup_cwd()

  n.exec_lua(function()
    require("nvim-tree").setup(config)
  end)

  M.add_nvt_attr_ids(screen)

  M.use_dummy_clipboard()

  return screen
end

---Subscribed events captured during test execution
---@class (exact) nvt.functest.event
---@field event_type string value of nvim_tree.api.events.Event
---@field payload table deep copy

---Subscribe to an event, to be recorded in session global NVT_FUNCTEST_EVENTS nvt.functest.event[]
---Assert events via events_received
---@param event_type nvim_tree.api.events.Event [nvim_tree_events_kind]
function M.event_subscribe(event_type)
  n.exec_lua(function()
    local api = require("nvim-tree.api")

    api.events.subscribe(event_type, function(payload)
      table.insert(NVT_FUNCTEST_EVENTS, {
        event_type = event_type,
        payload = vim.deepcopy(payload),
      })
    end)
  end)
end

---Clear all recorded events in NVT_FUNCTEST_EVENTS
function M.events_clear()
  n.exec_lua(function()
    NVT_FUNCTEST_EVENTS = {}
  end)
end

---Setup a dummy clipboard named NVT_FUNCTEST_CLIPBOARD containing the global NVT_FUNCTEST_CLIPBOARD_LINES
function M.use_dummy_clipboard()
  n.exec_lua(function()
    vim.g.clipboard = {
      name = "NVT_FUNCTEST_CLIPBOARD",
      copy = {
        ["+"] = function(lines)
          NVT_FUNCTEST_CLIPBOARD_LINES = lines
        end
      },
      paste = {
        ["+"] = function()
          return NVT_FUNCTEST_CLIPBOARD_LINES
        end
      },
    }
  end)
end

---Set concrete attr_ids for all nvim-tree highlight groups
---Must be called after nvim-tree setup
---These groups are uniquely defined in the test context by appearance/init.lua highlight_functest
---@param screen test.functional.ui.screen
function M.add_nvt_attr_ids(screen)
  local attr_ids = {}

  for name, hl in pairs(n.api.nvim_get_hl(0, { create = false, link = true, })) do
    if name:match("^NvimTree.*") then
      attr_ids[name] = { foreground = hl.fg, background = hl.bg }
    end
  end

  screen:add_extra_attr_ids(attr_ids)
end

return M
