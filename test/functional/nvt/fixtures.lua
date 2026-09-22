local n = vim
if not n.fn then
  n = require("test.functional.testnvim")()
end

local M = {}

-- remove $NVT_FUNC_TMP
-- cd to $NVT_FUNC_TMP
-- if $NVT_FUNC_DATA exists:recursively copy it to $NVT_FUNC_TMP and cd
function M.setup_dirs()
  local tmp = os.getenv("NVT_FUNC_TMP")
  if not tmp then
    return
  end

  -- blow away temp
  n.fn.system({ "rm", "-r", "-f", "-v", tmp })
  n.fn.system({ "mkdir", "-p", "-v", tmp })

  -- always cd to tmp
  n.api.nvim_set_current_dir(tmp)

  -- maybe copy entire data directory
  local data = os.getenv("NVT_FUNC_DATA")
  if data and vim.uv.fs_stat(data) then
    n.fn.system({ "cp", "-p", "-r", "-v", data, tmp })
    n.api.nvim_set_current_dir(tmp .. "/data")
  end
end

return M
