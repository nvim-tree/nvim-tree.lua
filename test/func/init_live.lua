-- match the test screen size: <Leader>r to reapply if the terminal is not cooperating
local function screen_resize()
  vim.o.columns = 80
  vim.o.lines = 24
end

---dump the screen to $NVT_TMP_FUNC/dump.txt: <Leader>d
---pipe is appended to each line
---caret is inserted at the cursor position
local function live_dump()
  screen_resize()

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

  local dump_path = os.getenv("NVT_TMP_FUNC") .. "/dump.txt"

  -- dump to file
  vim.fn.writefile(lines, dump_path)
  vim.api.nvim_command("echo 'dumped screen to " .. dump_path .. "'")

  -- try to open it
  vim.ui.open(dump_path)
end

vim.keymap.set("n", "<Leader>d", live_dump,     { remap = false, })
vim.keymap.set("n", "<Leader>r", screen_resize, { remap = false, })

---set the screen size to match tests
screen_resize()

-- use dark background for readability under dark and light
vim.o.background = "dark"

-- move to the data directory
vim.api.nvim_set_current_dir(os.getenv("NVT_TMP_FUNC_DATA") or "")

---add the plugin under test
vim.api.nvim_command("packadd nvim-tree.lua")
require("nvim-tree").setup({})
