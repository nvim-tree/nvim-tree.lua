local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")


---@class (exact) nvt.functest.event
---@field event_type string value of nvim_tree.api.events.Event
---@field payload table deep copy


---Globals used within test session context, noted in this test context only for type definition
---@diagnostic disable: global-element

---@type boolean
NVT_FUNCTEST_CONTEXT = true

---@type nvt.functest.event[]
NVT_FUNCTEST_EVENTS = {}

---@type string[]
NVT_FUNCTEST_CLIPBOARD_LINES = {}

---@diagnostic enable: global-element


local M = {}

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

  n.exec_lua(function()
    vim.opt.packpath:append(os.getenv("NVT_FUNC_PACKPATH") or "")
    vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})

    ---@diagnostic disable: global-element
    NVT_FUNCTEST_CONTEXT = true
    NVT_FUNCTEST_EVENTS = {}
    NVT_FUNCTEST_CLIPBOARD_LINES = {}
    ---@diagnostic enable: global-element
  end)

  -- Change to the temp test (data) directory
  -- TODO neovim 0.13: replace with vim.system calls; vim.system is not currenctly available in neovim 0.12 func tests
  local out = n.fn.system({ os.getenv("NVT_FUNC_SCRIPT_CREATE_TEST_CWD"), })
  local dir = out:match("^DIR=(.*)$") or error(out)
  n.api.nvim_set_current_dir(dir)

  n.exec_lua(function()
    require("nvim-tree").setup(config)
  end)

  M.add_nvt_attr_ids(screen)

  M.use_dummy_clipboard()

  return screen
end

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
    NVT_FUNCTEST_EVENTS = {} ---@diagnostic disable-line: global-element
  end)
end

---Setup a dummy clipboard using the global NVT_DUMMY_CLIPBOARD_LINES
function M.use_dummy_clipboard()
  n.exec_lua(function()
    vim.g.clipboard = {
      name = "NVT_DUMMY_CLIPBOARD",
      copy = {
        ["+"] = function(lines)
          NVT_FUNCTEST_CLIPBOARD_LINES = lines ---@diagnostic disable-line: global-element
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
---These groups are uniquely defined in the test context in TODO
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
