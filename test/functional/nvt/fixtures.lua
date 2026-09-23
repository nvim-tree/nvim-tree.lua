local M = {}

---create and return the absolute path of the directory to execute tests in
---recursively copies data if present
---@param system fun(cmd: string|string[], input?: string|string[]|integer): string vim.fn.system to use as it depends on the context
---@return string path
function M.create_test_dir(system)
  local out = system({ os.getenv("NVT_FUNC_NVT_ROOT") .. "/test/functional/nvt/create_test_cwd.sh" })

  return out:match("^DIR=(.*)$") or error(out)
end

return M
