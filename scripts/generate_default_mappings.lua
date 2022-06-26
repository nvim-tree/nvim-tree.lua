-- luacheck:ignore 113
---@diagnostic disable: undefined-global

-- write DEFAULT_MAPPINGS in various formats

local max_key_help = 0
local max_key_lua = 0
local max_action_help = 0
local outs_help = {}
local outs_lua = {}

for _, m in pairs(DEFAULT_MAPPINGS) do
  local out
  if type(m.key) == "table" then
    local first = true
    local keys_lua = "key = {"
    for _, sub_key in pairs(m.key) do
      -- lua
      keys_lua = string.format('%s%s "%s"', keys_lua, first and "" or ",", sub_key)

      -- help
      out = {}
      if first then
        out.action = m.action
        out.desc = m.desc
        first = false
      else
        out.action = ""
        out.desc = ""
      end
      out.key = string.format("`%s`", sub_key)
      max_action_help = math.max(#out.action, max_action_help)
      max_key_help = math.max(#out.key, max_key_help)
      table.insert(outs_help, out)
    end

    -- lua
    out = {}
    out.key = string.format("%s },", keys_lua)
    table.insert(outs_lua, out)
  else
    -- help
    out = {}
    out.action = m.action
    out.desc = m.desc
    out.key = string.format("`%s`", m.key)
    table.insert(outs_help, out)
    max_action_help = math.max(#out.action, max_action_help)
    max_key_help = math.max(#out.key, max_key_help)

    -- lua
    out = {}
    out.key = string.format('key = "%s",', m.key)
    table.insert(outs_lua, out)
  end

  --lua
  out.action = string.format('action = "%s"', m.action)
  max_key_lua = math.max(#out.key, max_key_lua)
end

-- help
local file = io.open("/tmp/DEFAULT_MAPPINGS.help", "w")
io.output(file)
io.write "\n"
local fmt = string.format("%%-%d.%ds  %%-%d.%ds  %%s\n", max_key_help, max_key_help, max_action_help, max_action_help)
for _, m in pairs(outs_help) do
  if m.action == "" then
    io.write(string.format("%s\n", m.key))
  else
    io.write(string.format(fmt, m.key, m.action, m.desc))
  end
end
io.write "\n"
io.close(file)

-- lua
file = io.open("/tmp/DEFAULT_MAPPINGS.lua", "w")
io.output(file)
fmt = string.format("    { %%-%d.%ds %%s }\n", max_key_lua, max_key_lua)
for _, m in pairs(outs_lua) do
  io.write(string.format(fmt, m.key, m.action))
end
io.close(file)
