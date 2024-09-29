local core = require("nvim-tree.core")
local find_file = require("nvim-tree.actions.finders.find-file").fn

local M = {}

---@param search_dir string|nil
---@param input_path string
---@return string|nil
local function search(search_dir, input_path)
  local realpaths_searched = {}
  local explorer = core.get_explorer()

  if not explorer then
    return
  end

  if not search_dir then
    return
  end

  ---@param dir string
  ---@return string|nil
  local function iter(dir)
    local realpath, path, name, stat, handle, _

    local filter_status = explorer.filters:prepare()

    handle, _ = vim.loop.fs_scandir(dir)
    if not handle then
      return
    end

    realpath, _ = vim.loop.fs_realpath(dir)
    if not realpath or vim.tbl_contains(realpaths_searched, realpath) then
      return
    end
    table.insert(realpaths_searched, realpath)

    name, _ = vim.loop.fs_scandir_next(handle)
    while name do
      path = dir .. "/" .. name

      ---@type uv.fs_stat.result|nil
      stat, _ = vim.loop.fs_stat(path)
      if not stat then
        break
      end

      if not explorer.filters:should_filter(path, stat, filter_status) then
        if string.find(path, "/" .. input_path .. "$") then
          return path
        end

        if stat.type == "directory" then
          path = iter(path)
          if path then
            return path
          end
        end
      end

      name, _ = vim.loop.fs_scandir_next(handle)
    end
  end

  return iter(search_dir)
end

function M.fn()
  if not core.get_explorer() then
    return
  end

  -- temporarily set &path
  local bufnr = vim.api.nvim_get_current_buf()

  local path_existed, path_opt
  if vim.fn.has("nvim-0.10") == 1 then
    path_existed, path_opt = pcall(vim.api.nvim_get_option_value, "path", { buf = bufnr })
    vim.api.nvim_set_option_value("path", core.get_cwd() .. "/**", { buf = bufnr })
  else
    path_existed, path_opt = pcall(vim.api.nvim_buf_get_option, bufnr, "path") ---@diagnostic disable-line: deprecated
    vim.api.nvim_buf_set_option(bufnr, "path", core.get_cwd() .. "/**") ---@diagnostic disable-line: deprecated
  end

  vim.ui.input({ prompt = "Search: ", completion = "file_in_path" }, function(input_path)
    if not input_path or input_path == "" then
      return
    end
    -- reset &path
    if path_existed then
      if vim.fn.has("nvim-0.10") == 1 then
        vim.api.nvim_set_option_value("path", path_opt, { buf = bufnr })
      else
        vim.api.nvim_buf_set_option(bufnr, "path", path_opt) ---@diagnostic disable-line: deprecated
      end
    else
      if vim.fn.has("nvim-0.10") == 1 then
        vim.api.nvim_set_option_value("path", nil, { buf = bufnr })
      else
        vim.api.nvim_buf_set_option(bufnr, "path", nil) ---@diagnostic disable-line: deprecated
      end
    end

    -- strip trailing slash
    input_path = string.gsub(input_path, "/$", "")

    -- search under cwd
    local found = search(core.get_cwd(), input_path)
    if found then
      find_file(found)
    end
  end)
end

return M
