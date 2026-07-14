local notify = require("nvim-tree.notify")

local M = {}

local storepath = vim.fn.stdpath("data") .. "/nvim-tree-session.json"

local function decode_session_file()
  local file = io.open(storepath, "r")

  if file then
    local content = file:read("*all")
    file:close()
    if content and content ~= "" then
      return vim.json.decode(content)
    end
  end
  -- Notifying on failure could be noisy, as it'd happen if the file simply did not exist
end

local function write_session_file(session_file_content)
  local file, errmsg = io.open(storepath, "w")

  if file then
    file:write(vim.json.encode(session_file_content))
    file:close()
  else
    notify.warn(string.format("Invalid session file (%s): %s", storepath, errmsg))
  end
end

function M.save()
  -- We either always save the session data, which ends up populating the storepath with empty data
  -- Or we gate by the tree's visibility, which could create "out of sync" scenario:
  -- if the tree is initially open and the session is saved, it won't be overridden later,
  -- if the tree is no longer visible. However, when restoring, this is harmless.
  if require("nvim-tree.api").tree.is_visible({ any_tabpage = true }) then
    local ok, session_file_content = pcall(decode_session_file)

    if not ok then
      notify.warn(string.format("Failed to decode session file (%s): %s", storepath, session_file_content))
      return
    end

    -- might be nil at this point
    session_file_content = session_file_content or {}

    local cwd = require("nvim-tree.core").get_cwd()

    session_file_content[vim.v.this_session] = { cwd = cwd }

    local ok2, err = pcall(write_session_file, session_file_content)

    if not ok2 then
      notify.warn(string.format("Failed to write session file (%s): %s", storepath, err))
    end
  end
end

function M.restore()
  local api = require("nvim-tree.api").tree

  ---@type table<integer,boolean>
  local tabs = {}

  local ok, session_file_content = pcall(decode_session_file)

  -- Failing to restore cwd is not fatal, we can continue
  if not ok then
    notify.warn(string.format("Failed to decode session file (%s): %s", storepath, session_file_content))
  end

  local path = session_file_content and session_file_content[vim.v.this_session] and session_file_content[vim.v.this_session].cwd or nil

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
