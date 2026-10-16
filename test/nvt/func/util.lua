---General test utils that to not require test infra, for use by tests and live

local M = {}

---Return the value of an environment variable, asserting presence
---return @string
function M.env(name)
  local val = os.getenv(name)
  assert(val, "$" .. name .. " not set")
  return val
end

---Execute vim.system and waits
---Assers RC=0 only for nvim > 0.12
---@param cmd string[] Command to execute
function M.sys(cmd)
  if vim.system then
    local out = vim.system(cmd):wait()
    assert(out.code == 0, vim.inspect(out))
  else
    -- vim.system and n.system are not available for neovim 0.12 func tests
    -- this will fail silently
    require("test.functional.testnvim")().fn.system(cmd)
  end
end

---Create /tmp/nvt_func or populated /tmp/nvt_func/data
---@return string absolute path
function M.setup_cwd()
  local cwd, dir_test = M.env("NVT_FUNC_DIR_CWD"), M.env("NVT_FUNC_DIR_TEST")

  -- always blow away and recreate the cwd of the test instance
  M.sys({ "rm", "-rf", cwd })
  M.sys({ "mkdir", "-p", cwd })

  -- if data is present, recursively copy it and use that as cwd
  local dir_test_data = dir_test .. "/data"
  if vim.uv.fs_stat(dir_test_data) then
    M.sys({ "cp", "-p", "-r", dir_test_data, cwd })
    cwd = cwd .. "/data"
  end

  return cwd
end

return M
