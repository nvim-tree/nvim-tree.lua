local get_node = require("nvim-tree.lib").get_node_at_cursor
local FloatPreview = {}
FloatPreview.__index = FloatPreview

local preview_au = "float_preview_au"
vim.api.nvim_create_augroup(preview_au, { clear = true })

function FloatPreview:new(cfg)
  local prev = {}
  setmetatable(prev, FloatPreview)

  cfg = cfg or {
    scroll_lines = 20,
    mapping = {
      down = { "<C-d>" },
      up = { "<C-e>", "<C-u>" }
    }
  }

  prev.buf = nil
  prev.win = nil
  prev.path = nil
  prev.current_line = 1
  prev.max_line = 999999
  prev.disabled = false
  prev.cfg = cfg

  local function action_wrap(f)
    return function(...)
      prev:close()
      local r = f(...)
      prev:preview_under_cursor()
      return r
    end
  end

  return prev, action_wrap
end

function FloatPreview:close()
  if self.path ~= nil then
    pcall(vim.api.nvim_win_close, self.win, { force = true })
    pcall(vim.api.nvim_buf_delete, self.buf, { force = true })
    self.win = nil
    self.buf = nil
    self.path = nil
    self.current_line = 1
    self.max_line = 999999
  end
end

function FloatPreview:preview(path)
  self.path = path
  self.buf = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_buf_set_option(self.buf, "bufhidden", "delete")
  vim.api.nvim_buf_set_option(self.buf, "readonly", true)

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  local prev_height = math.ceil(height / 2)
  local opts = {
    -- style = "minimal",
    relative = "win",
    width = math.ceil(width / 2),
    height = prev_height,
    row = vim.fn.line("."),
    col = vim.fn.winwidth(0) + 1,
    border = "rounded",
    focusable = false,
    noautocmd = true,
  }

  self.win = vim.api.nvim_open_win(self.buf, true, opts)
  local cmd = string.format("edit %s", vim.fn.fnameescape(self.path))
  vim.api.nvim_command(cmd)
  self.max_line = vim.fn.line("$")

  local ok, out = pcall(vim.filetype.match, { buf = self.buf, filename = self.path })
  if ok and out then
    cmd = string.format("set filetype=%s", out)
    pcall(vim.api.nvim_command, cmd)
  end
end

function FloatPreview:preview_under_cursor()
  local _, node = pcall(get_node)
  if not node then
    self:close()
    return
  end

  if not node.absolute_path then
    self:close()
    return
  end

  if node.absolute_path == self.path then
    return
  end
  self:close()
  if node.type ~= "file" then
    return
  end

  local win = vim.api.nvim_get_current_win()
  self:preview(node.absolute_path)

  local ok, _ = pcall(vim.api.nvim_set_current_win, win)
  if not ok then
    self:close()
  end
end

function FloatPreview:scroll(line)
  if self.win then
    local ok, _ = pcall(vim.api.nvim_win_set_cursor, self.win, { line, 0 })
    if ok then
      self.current_line = line
    end
  end
end

function FloatPreview:scroll_down()
  if self.buf then
    local next_line = math.min(self.current_line + self.cfg.scroll_lines, self.max_line)
    self:scroll(next_line)
  end
end

function FloatPreview:scroll_up()
  if self.buf then
    local next_line = math.max(self.current_line - self.cfg.scroll_lines, 1)
    self:scroll(next_line)
  end
end

function FloatPreview:attach(bufnr)
  for _, key in ipairs(self.cfg.mapping.up) do
    vim.keymap.set("n", key, function() self:scroll_up() end, { buffer = bufnr })
  end

  for _, key in ipairs(self.cfg.mapping.down) do
    vim.keymap.set("n", key, function() self:scroll_down() end, { buffer = bufnr })
  end

  vim.api.nvim_create_autocmd({ "User CloseNvimFloatPreview" }, {
    callback = function() self:close() end,
    group = preview_au,
  })
  vim.api.nvim_create_autocmd({ "CursorHold" }, {
    buffer = bufnr,
    group = preview_au,
    callback = function()
      self:preview_under_cursor()
    end,
  })
end

return FloatPreview
