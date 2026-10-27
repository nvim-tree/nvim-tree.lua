local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local nu = require("test.nvt.func.util")


---Globals used within test session context, noted in this test context only for type definition
---@type boolean
NVT_FUNCTEST_CONTEXT = true
---@type test.nvt.func.fixtures.Event[]
NVT_FUNCTEST_EVENTS = {}
---@type string[]
NVT_FUNCTEST_CLIPBOARD_LINES = {}

local M = {
  --- Minimal default screen options for create_session, for considerable performance optimisation
  --- Override as needed via test.functional.ui.screen.Opts.screen_opts
  --- @type test.functional.ui.screen.Opts
  default_screen_opts = {
    ext_linegrid = false,
    ext_multigrid = false,
    ext_popupmenu = false,
    ext_wildmenu = false,
  },
}

---@class (exact) test.nvt.func.fixtures.create_session.Opts
---@field data? string relative path of data directory to copy for test instance cwd
---@field config? nvim_tree.config passed to nvim-tree.setup
---@field width? integer default 80
---@field height? integer default 24
---@field screen_opts? test.functional.ui.screen.Opts overrides M.default_screen_opts

---Create a new neovim functest session with
---- nvim-tree.lua package added
---- fresh test data directory created and cd'd into
---- nvim-tree setup called
---- nvim-tree HL attr_ids added
---- dummy clipboard setup
---@param opts? test.nvt.func.fixtures.create_session.Opts
---@return test.functional.ui.screen
function M.create_session(opts)
  opts = opts or {}
  opts.width = opts.width or 80
  opts.height = opts.height or 24
  local screen_opts = vim.tbl_deep_extend("force", M.default_screen_opts, opts.screen_opts or {})

  -- instantiate a new session (nvim instance) and its screen
  n.clear({
    args = {
      "--cmd", "set packpath^=" .. nu.env("NVT_FUNC_PACKPATH"),
      "--cmd", "packadd nvim-tree.lua",
    }
  })
  local screen = Screen.new(opts.width, opts.height, screen_opts)

  -- create the test instance cwd
  local cwd = nu.setup_cwd(opts.data)

  -- add the nvim-tree package, setup globals and cd
  n.exec_lua(function()
    -- setup globals
    NVT_FUNCTEST_CONTEXT = true
    NVT_FUNCTEST_EVENTS = {}
    NVT_FUNCTEST_CLIPBOARD_LINES = {}

    -- test intance dir
    vim.api.nvim_set_current_dir(cwd)

    -- setup nvim-tree with requested config
    require("nvim-tree").setup(opts.config)
  end)

  -- create attr_ids for all nvim-tree test highlight groups
  M.add_nvt_attr_ids(screen)

  -- instantiate the test clipboard
  M.use_dummy_clipboard()

  return screen
end

---@class (exact) test.nvt.func.fixtures.Event
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
  -- TODO only 2 necessary entries merged then set_default_attr_ids results in less spikey performance
  -- no obvious pattern RE string vs int indexed
  -- this would be good to use Normal instead of 1
  -- local attr_ids = {
  --   [1] = { foreground = Screen.colors.Blue1, bold = true },
  --   [2] = { reverse = true },
  -- }

  for name, hl in pairs(n.api.nvim_get_hl(0, { create = false, link = true, })) do
    if name:match("^NvimTree.*") then
      attr_ids[name] = { foreground = hl.fg, background = hl.bg }
    end
  end

  screen:add_extra_attr_ids(attr_ids)
end

---Feed keys synchronously (deferred), blocking the test thread and instance until the instance's main loop is complete.
---This is needed as api-fast input will execute lua callbacks (such as nvim-tree mappings) then execute the next input without waiting for the callback to complete.
---Calls feedkeys() (non-deferred, api-fast) then poke_eventloop() for each input passed.
---See :help api-fast
---@param inputs string[]
function M.feed_sync(inputs)
  for _, v in ipairs(inputs) do
    -- api-fast, does not wait for callbacks or input to complete
    n.feed(v)

    -- defer until complete
    n.poke_eventloop()
  end
end

return M
