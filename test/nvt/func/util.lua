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
---@param dir_data? string relative path of data directory to copy for test instance cwd
---@return string absolute path
function M.setup_cwd(dir_data)
  local cwd = M.env("NVT_FUNC_DIR_CWD")

  -- always blow away and recreate the cwd of the test instance
  M.sys({ "rm", "-rf", cwd })
  M.sys({ "mkdir", "-p", cwd })

  -- if data is present, recursively copy it and use that as cwd
  if dir_data then
    local abs_dir_data = M.env("NVT_FUNC_DIR_ROOT") .. "/" .. dir_data
    local _, err = vim.uv.fs_stat(abs_dir_data)
    assert(not err, err)

    M.sys({ "cp", "-p", "-r", abs_dir_data, cwd })
    cwd = cwd .. "/data"

    print("  created test cwd " .. cwd .. " from " .. abs_dir_data)
  else
    print("  created empty test cwd " .. cwd)
  end

  return cwd
end

return M
