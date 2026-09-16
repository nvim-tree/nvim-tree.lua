local dump_path = "/tmp/nvt_test_func/dump.txt"

-- match the test screen size: <Leader>r to reapply if the terminal is not cooperating
local function screen_resize()
  vim.o.columns = 80
  vim.o.lines = 24
end

---dump the screen to dump_path: <Leader>d
---pipe is appended to each line
---caret is inserted at the cursor position
---this is global so that we can execute it as a command, without changing cursor position
---@diagnostic disable-next-line: missing-global-doc, global-element
function LIVE_DUMP()
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

  -- dump to file
  vim.fn.writefile(lines, dump_path)
  vim.api.nvim_command("echo 'dumped screen to " .. dump_path .. "'")

  -- try to open it
  vim.ui.open(dump_path)
end

vim.keymap.set("n", "<Leader>d", "<Cmd>lua LIVE_DUMP()<CR>", { remap = false, })
vim.keymap.set("n", "<Leader>r", screen_resize,              { remap = false, })

---set the screen size to match tests
screen_resize()

-- use dark background for readability under dark and light
vim.o.background = "dark"

-- move to the data directory
local nvt_test_data = os.getenv("NVT_DIR_TEST_DATA")
if nvt_test_data then
  vim.api.nvim_set_current_dir(nvt_test_data)
end

---add the plugin under test
vim.api.nvim_command("packadd nvim-tree.lua")
require("nvim-tree").setup({})
