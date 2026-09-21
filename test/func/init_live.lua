-- match the test screen size: <Leader>r to reapply if the terminal is not cooperating
local function screen_resize()
  vim.o.columns = 80
  vim.o.lines = 24
end

---dump the screen to $NVT_FUNC_TMP/dump.txt: <Leader>d for raw, <Leader>c for collapsed
---pipe is appended to each line
---caret is inserted at the cursor position
---@param collapse boolean identical lines collapsed with "*n" appended
local function live_dump(collapse)
  local dump_path = os.getenv("NVT_FUNC_TMP") .. "/dump.txt"

  local function cap_lines()
    -- absolute cursor position
    local cursor = { col = vim.fn.screencol(), row = vim.fn.screenrow(), }

    -- capture all screen lines
    local lines = {}
    for row = 1, vim.o.lines do
      local line = ""
      for col = 1, vim.o.columns do
        if row == cursor.row and col == cursor.col then
          line = line .. "^"
        end
        line = line .. vim.fn.screenstring(row, col)
      end
      lines[row] = line .. "|"
    end

    return lines
  end

  local function compress_lines(lines)
    local ret = {}
    local n = 0

    for i = 1, #lines + 1 do
      if lines[i - 1] == lines[i] then
        n = n + 1
      else
        if n > 0 then
          table.insert(ret, lines[i - 1] .. "*" .. n + 1)
        else
          table.insert(ret, lines[i - 1])
        end
        n = 0
      end
    end

    return ret
  end

  local lines = cap_lines()

  if collapse then
    lines = compress_lines(lines)
  end

  -- dump to file
  vim.fn.writefile(lines, dump_path)
  vim.api.nvim_command("echo 'dumped screen to " .. dump_path .. "'")

  -- try to open it
  vim.ui.open(dump_path)
end

vim.keymap.set("n", "<Leader>u", function() live_dump(false) end, { remap = false, })
vim.keymap.set("n", "<Leader>c", function() live_dump(true) end,  { remap = false, })
vim.keymap.set("n", "<Leader>r", screen_resize,                   { remap = false, })

---set the screen size to match tests
screen_resize()

-- use dark background for readability under dark and light
vim.o.background = "dark"

---add the plugin under test
vim.api.nvim_command("packadd nvim-tree.lua")
require("nvim-tree").setup({})

-- remove $NVT_FUNC_TMP
-- cd to $NVT_FUNC_TMP
-- if $NVT_FUNC_SRC/data exists:recursively copy it to $NVT_FUNC_TMP and cd
local function setup_dirs()
  local n = vim
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

setup_dirs()
