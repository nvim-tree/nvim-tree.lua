local M = {}

local function load_state()
  return vim.json.decode(vim.g.NvimTreeState or "{}") or {}
end

function M.save()
  local cwd = require("nvim-tree.core").get_cwd()
  vim.g.NvimTreeState = vim.json.encode({ cwd = cwd })
end

function M.restore()
  local api = require("nvim-tree.api").tree

  ---@type table<integer,boolean>
  local tabs = {}

  local ok, session_state = pcall(load_state)
  if not ok then
    require("nvim-tree.notify").warn(string.format("Failed to restore cwd: %s", session_state))
  end
  local path = session_state and session_state.cwd or nil

  -- Save tabs with leftover nvim-tree buffers
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if api.is_tree_buf(buf) then
        tabs[tab] = true
      end
    end
  end

  -- The new window may inherit options from the current one if we don't schedule
  vim.schedule(function()
    api.close_in_all_tabs()

    for tab, _ in pairs(tabs) do
      if vim.api.nvim_tabpage_is_valid(tab) then
        local win = vim.api.nvim_tabpage_get_win(tab)

        -- Invoke `open` from each tab's current window to prevent having to switch tabs
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_call(win, function()
            api.open({ path = path })
          end)
        end
      end
    end
  end)
end

return M
