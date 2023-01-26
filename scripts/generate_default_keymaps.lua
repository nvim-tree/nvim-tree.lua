-- luacheck:ignore 113
---@diagnostic disable: undefined-global

-- write DEFAULT_KEYMAPS in various formats

local max_key = 0
local max_short = 0
local max_callback = 0
local outs_help = {}

for _, m in pairs(DEFAULT_KEYMAPS) do
  local first = true
  local keys = type(m.key) == "table" and m.key or { m.key }
  for _, key in ipairs(keys) do
    local out = {}
    out.key = string.format("`%s`", key)
    max_key = math.max(#out.key, max_key)
    if first then
      out.short = m.desc.short
      max_short = math.max(#out.short, max_short)
      out.long = m.desc.long
      first = false
    end
    table.insert(outs_help, out)
  end
  max_callback = math.max(#m.callback, max_callback)
end

-- help
local file = io.open("/tmp/DEFAULT_KEYMAPS.help", "w")
io.output(file)
io.write "\n"
local fmt = string.format("%%-%d.%ds  %%-%d.%ds  %%s\n", max_key, max_key, max_short, max_short)
for _, m in pairs(outs_help) do
  if not m.short then
    io.write(string.format("%s\n", m.key))
  else
    io.write(string.format(fmt, m.key, m.short, m.long))
  end
end
io.write "\n"
io.close(file)

-- legacy callback mappings
file = io.open("/tmp/LEGACY_CALLBACKS.lua", "w")
io.output(file)
io.write "local LEGACY_CALLBACKS = {\n"
for _, m in pairs(DEFAULT_KEYMAPS) do
  io.write(string.format('  %s = "%s",\n', m.legacy_action, m.callback))
end
io.write "}\n"
io.close(file)
