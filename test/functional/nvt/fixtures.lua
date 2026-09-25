local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")

local M = {}

---@class (exact) nvt.functest.event
---@field event_type nvim_tree.api.events.Event [nvim_tree_events_kind]
---@field payload table deep copy

---Create a new neovim session with
---- nvim-tree.lua package added
---- fresh test data directory created and cd'd into
---@param options? test.functional.ui.screen.Opts
---@return test.functional.ui.screen
function M.create_session(options)
  n.clear()

  local screen = Screen.new(80, 24, options)

  n.exec_lua(function()
    vim.api.nvim_cmd({ cmd = "packadd", args = { "nvim-tree.lua" } }, {})

    ---@type nvt.functest.event[]
    NVT_FUNCTEST_EVENTS = NVT_FUNCTEST_EVENTS or {} ---@diagnostic disable-line: global-element
  end)

  -- TODO neovim 0.13: replace with vim.system calls; vim.system is not currenctly available in neovim 0.12 func tests
  local out = n.fn.system({ os.getenv("NVT_FUNC_DIR_ROOT") .. "/test/functional/nvt/create_test_cwd.sh" })
  local dir = out:match("^DIR=(.*)$") or error(out)

  n.api.nvim_set_current_dir(dir)

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

--- Reset all NvimTree* highlight groups to just a unique foreground colour
--- Return attr_ids to match
--- Add a CL variant with the same background colour as NvimTreeCursorLine
--- May be executed repeatedly however results are not idempotent: foreground colours will be different, depending on vim.api.nvim_get_hl iteration order
function M.simple_attr_ids()
  local attr_ids = {}

  -- math.random(tonumber('0x707070'),tonumber('0x909090'))
  local bg_rgb, bg_hex = 8758352, "#85a450"

  -- build the cursor line first, background only
  attr_ids["NvimTreeCursorLine"] = { background = bg_rgb }
  n.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = bg_hex })

  -- unique colour for each group, descending from #fefefe
  local i, r, g, b = 1, 254, 254, 254
  local rgb, hex

  for group, _ in pairs(n.api.nvim_get_hl(0, { create = false })) do
    if group ~= "NvimTreeCursorLine" and group:match("^NvimTree.*") and not group:match(".*CL$") then
      -- next unique fg colour
      rgb = r * 256 * 256 + g * 256 + b
      hex = string.format("#%x", rgb)
      i = i + 1
      if (i % 256 == 0) then
        b = 254
        g = 254
        r = r - 1
      elseif (i % 16 == 0) then
        b = 254
        g = g - 1
      else
        b = b - 1
      end

      -- add the group's concrete definition with fg only
      attr_ids[group] = { foreground = rgb }
      n.api.nvim_set_hl(0, group, { fg = hex })

      -- create an NvimTreeCursorLine variant
      attr_ids[group .. "CL"] = { foreground = rgb, background = bg_rgb }
      n.api.nvim_set_hl(0, group .. "CL", { fg = hex, bg = bg_hex })
    end
  end

  return attr_ids
end

return M
