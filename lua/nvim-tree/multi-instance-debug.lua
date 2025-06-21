local globals = require("nvim-tree.globals")

local M = {}

--- Debugging only.
--- Tabs show WINID_BY_TABID winid and BUFNR_BY_TABID bufnr for the tab.
--- Orphans for inexistent tab_ids are shown at the right.
--- lib.target_winid is always shown at the right next to a close button.
--- Enable with:
---   vim.opt.tabline = "%!v:lua.require('nvim-tree.explorer.view').tab_line()"
---   vim.opt.showtabline = 2
---@return string
function M.tab_line()
  local tabids = vim.api.nvim_list_tabpages()
  local tabid_cur = vim.api.nvim_get_current_tabpage()

  local bufnr_by_tabid = vim.deepcopy(globals.BUFNR_BY_TABID)
  local winid_by_tabid = vim.deepcopy(globals.WINID_BY_TABID)

  local tl = "%#TabLine#"

  for i, tabid in ipairs(tabids) do
    -- click to select
    tl = tl .. "%" .. i .. "T"

    -- style
    if tabid == tabid_cur then
      tl = tl .. "%#StatusLine#|"
    else
      tl = tl .. "|%#TabLine#"
    end

    -- tab_id itself
    tl = tl .. " t" .. tabid

    -- winid, if present
    local tp = globals.WINID_BY_TABID[tabid]
    if tp then
      tl = tl .. " w" .. (tp or "nil")
    else
      tl = tl .. "      "
    end

    -- bufnr, if present
    local bpt = globals.BUFNR_BY_TABID[tabid]
    if bpt then
      tl = tl .. " b" .. bpt
    else
      tl = tl .. "   "
    end

    tl = tl .. " "

    -- remove actively mapped
    bufnr_by_tabid[tabid] = nil
    winid_by_tabid[tabid] = nil
  end

  -- close last and reset
  tl = tl .. "|%#CursorLine#%T"

  -- collect orphans
  local orphans = {}
  for tab_id, bufnr in pairs(bufnr_by_tabid) do
    orphans[tab_id] = orphans[tab_id] or {}
    orphans[tab_id].bufnr = bufnr
  end
  for tab_id, tp in pairs(winid_by_tabid) do
    orphans[tab_id] = orphans[tab_id] or {}
    orphans[tab_id].winid = tp
  end

  -- right-align
  tl = tl .. "%=%#TabLine#"

  -- print orphans
  for tab_id, orphan in pairs(orphans) do
    -- inexistent tab
    tl = tl .. "%#error#| t" .. tab_id

    -- maybe winid
    if orphan.winid then
      tl = tl .. " w" .. (orphan.winid or "nil")
    else
      tl = tl .. "      "
    end

    -- maybe bufnr
    if orphan.bufnr then
      tl = tl .. " b" .. orphan.bufnr
    else
      tl = tl .. "   "
    end
    tl = tl .. " "
  end

  -- target win id and close button
  tl = tl .. "|%#TabLine# twi" .. (require("nvim-tree.lib").target_winid or "?") .. " %999X| X |"

  return tl
end

function M.setup(opts)
  if not opts.experimental.multi_instance then
    return
  end

  vim.opt.tabline = "%!v:lua.require('nvim-tree.multi-instance-debug').tab_line()"
  vim.opt.showtabline = 2
end

return M
