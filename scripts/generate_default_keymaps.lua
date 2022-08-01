-- luacheck:ignore 113
---@diagnostic disable: undefined-global

-- write DEFAULT_KEYMAPS in various formats

local max_key_help = 0
local max_short_help = 0
local outs_help = {}

for _, m in pairs(DEFAULT_KEYMAPS) do
  local first = true
  local keys = type(m.key) == "table" and m.key or { m.key }
  for _, key in ipairs(keys) do
    local out = {}
    out.key = key
    max_key_help = math.max(#out.key, max_key_help)
    if first then
      out.short = m.desc.short
      max_short_help = math.max(#out.short, max_short_help)
      out.long = m.desc.long
      first = false
    end
    table.insert(outs_help, out)
  end
end

-- help
local file = io.open("/tmp/DEFAULT_KEYMAPS.help", "w")
io.output(file)
io.write "\n"
local fmt = string.format("%%-%d.%ds  %%-%d.%ds  %%s\n", max_key_help, max_key_help, max_short_help, max_short_help)
for _, m in pairs(outs_help) do
  if not m.short then
    io.write(string.format("%s\n", m.key))
  else
    io.write(string.format(fmt, m.key, m.short, m.long))
  end
end
io.write "\n"
io.close(file)

-- lua on_attach
file = io.open("/tmp/DEFAULT_KEYMAPS.on_attach.lua", "w")
io.output(file)
io.write "local function on_attach(bufnr, mode, opts)\n"
io.write "local Api = require('nvim-tree.api')\n"
for _, m in pairs(DEFAULT_KEYMAPS) do
  local keys = type(m.key) == "table" and m.key or { m.key }
  for _, key in ipairs(keys) do
    io.write(string.format("  vim.keymap.set(mode, '%s', %s, opts)\n", key, m.callback))
  end
end
io.write "end\n"
io.close(file)
