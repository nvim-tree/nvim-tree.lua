local globals = require("nvim-tree.globals")

local M = {}

--- Debugging only.
--- Tabs show TABPAGES winnr and BUFNR_PER_TAB bufnr for the tab.
--- Orphans for inexistent tab_ids are shown at the right.
--- lib.target_winid is always shown at the right next to a close button.
--- Enable with:
---   vim.opt.tabline = "%!v:lua.require('nvim-tree.explorer.view').tab_line()"
---   vim.opt.showtabline = 2
---@return string
function M.tab_line()
  local tab_ids = vim.api.nvim_list_tabpages()
  local cur_tab_id = vim.api.nvim_get_current_tabpage()

  local bufnr_per_tab = vim.deepcopy(globals.BUFNR_PER_TAB)
  local tabpages = vim.deepcopy(globals.TABPAGES)

  local tl = "%#TabLine#"

  for i, tab_id in ipairs(tab_ids) do
    -- click to select
    tl = tl .. "%" .. i .. "T"

    -- style
    if tab_id == cur_tab_id then
      tl = tl .. "%#StatusLine#|"
    else
      tl = tl .. "|%#TabLine#"
    end

    -- tab_id itself
    tl = tl .. " t" .. tab_id

    -- winnr, if present
    local tp = globals.TABPAGES[tab_id]
    if tp then
      tl = tl .. " w" .. (tp.winnr or "nil")
    else
      tl = tl .. "      "
    end

    -- bufnr, if present
    local bpt = globals.BUFNR_PER_TAB[tab_id]
    if bpt then
      tl = tl .. " b" .. bpt
    else
      tl = tl .. "   "
    end

    tl = tl .. " "

    -- remove actively mapped
    bufnr_per_tab[tab_id] = nil
    tabpages[tab_id] = nil
  end

  -- close last and reset
  tl = tl .. "|%#CursorLine#%T"

  -- collect orphans
  local orphans = {}
  for tab_id, bufnr in pairs(bufnr_per_tab) do
    orphans[tab_id] = orphans[tab_id] or {}
    orphans[tab_id].bufnr = bufnr
  end
  for tab_id, tp in pairs(tabpages) do
    orphans[tab_id] = orphans[tab_id] or {}
    orphans[tab_id].winnr = tp.winnr
  end

  -- right-align
  tl = tl .. "%=%#TabLine#"

  -- print orphans
  for tab_id, orphan in pairs(orphans) do
    -- inexistent tab
    tl = tl .. "%#error#| t" .. tab_id

    -- maybe winnr
    if orphan.winnr then
      tl = tl .. " w" .. (orphan.winnr or "nil")
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
