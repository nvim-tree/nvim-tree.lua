local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local appearance = require("nvim-tree.appearance")

---Globals used within test session context, noted in this test context only for type definition
---@diagnostic disable: global-element

---@type nvt.functest.event[]
NVT_FUNCTEST_EVENTS = {}

---@type string[]
NVT_DUMMY_CLIPBOARD_LINES = {}

---@diagnostic enable: global-element


local M = {}

---@class (exact) nvt.functest.event
---@field event_type string value of nvim_tree.api.events.Event
---@field payload table deep copy

---Create a new neovim session with
---- nvim-tree.lua package added
---- fresh test data directory created and cd'd into
---@param width? integer
---@param height? integer
---@param options? test.functional.ui.screen.Opts
---@return test.functional.ui.screen
function M.create_session(width, height, options)
  n.clear()

  local screen = Screen.new(width or 80, height or 24, options)

  n.exec_lua(function()
    vim.opt.packpath:append(os.getenv("NVT_FUNC_PACKPATH") or "")
    vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})

    NVT_FUNCTEST_EVENTS = {} ---@diagnostic disable-line: global-element
    NVT_DUMMY_CLIPBOARD_LINES = {} ---@diagnostic disable-line: global-element
  end)

  -- TODO neovim 0.13: replace with vim.system calls; vim.system is not currenctly available in neovim 0.12 func tests
  local out = n.fn.system({ os.getenv("NVT_FUNC_SCRIPT_CREATE_TEST_CWD"), })
  local dir = out:match("^DIR=(.*)$") or error(out)

  n.api.nvim_set_current_dir(dir)

  M.setup_dummy_clipboard()

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
function M.setup_dummy_clipboard()
  n.exec_lua(function()
    vim.g.clipboard = {
      name = "NVT_DUMMY_CLIPBOARD",
      copy = {
        ["+"] = function(lines)
          NVT_DUMMY_CLIPBOARD_LINES = lines ---@diagnostic disable-line: global-element
        end
      },
      paste = {
        ["+"] = function()
          return NVT_DUMMY_CLIPBOARD_LINES
        end
      },
    }
  end)
end

---Reset all NvimTree* highlight groups to just a unique foreground colour
---Return attr_ids to match
---Add a CL variant with the same background colour as NvimTreeCursorLine
---May be executed repeatedly however results are not idempotent: foreground colours will be different, depending on vim.api.nvim_get_hl iteration order
---@param screen test.functional.ui.screen
function M.unique_highlight_groups(screen)
  local attr_ids = {}

  -- arbitrary "unique" value: math.random(tonumber('0x707070'),tonumber('0x909090'))
  local rgb_cl, hex_cl = 8758352, "#85a450"

  -- unique colour for each group, descending from #fefefe
  local i, r, g, b = 1, 254, 254, 254
  local rgb, hex

  -- build the cursor line first, background only
  local hgs = vim.tbl_filter(function(hg)
    if hg.group == "NvimTreeCursorLine" then
      attr_ids["NvimTreeCursorLine"] = { background = rgb_cl }
      n.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = hex_cl })
      return false
    else
      return true
    end
  end, appearance.HIGHLIGHT_GROUPS)

  for _, hg in ipairs(hgs) do
    -- next unique fg colour
    rgb = r * 256 * 256 + g * 256 + b
    hex = string.format("#%x", rgb)
    i = i + 1
    if (i % 256 == 0) then
      b, g, r = 254, 254, r - 1
    elseif (i % 16 == 0) then
      b, g = 254, g - 1
    else
      b = b - 1
    end

    -- add the group's concrete definition with fg only
    attr_ids[hg.group] = { foreground = rgb }
    n.api.nvim_set_hl(0, hg.group, { fg = hex })

    -- create an NvimTreeCursorLine variant
    attr_ids[hg.group .. "CL"] = { foreground = rgb, background = rgb_cl }
    n.api.nvim_set_hl(0, hg.group .. "CL", { fg = hex, bg = hex_cl })
  end

  screen:add_extra_attr_ids(attr_ids)
end

return M
