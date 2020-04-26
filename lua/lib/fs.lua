local api = vim.api
local luv = vim.loop

local M = {}

function M.get_cwd() return luv.cwd() end

function M.is_dir(path)
  local stat = luv.fs_lstat(path)
  return stat and stat.type == 'directory' or false
end

function M.is_symlink(path)
  local stat = luv.fs_lstat(path)
  return stat and stat.type == 'link' or false
end

function M.link_to(path)
  return luv.fs_readlink(path) or ''
end

function M.check_dir_access(path)
  if luv.fs_access(path, 'R') == true then
    return true
  else
    api.nvim_err_writeln('Permission denied: ' .. path)
    return false
  end
end

local handle = nil

local function run_process(opt, err, cb)
  handle = luv.spawn(opt.cmd, { args = opt.args }, vim.schedule_wrap(function(code)
    handle:close()
    if code ~= 0 then
      return api.nvim_err_writeln(err)
    end
    cb()
  end))
end

function M.rm(path, cb)
  local opt = { cmd='rm', args = {'-rf', path } };
  run_process(opt, 'Error removing '..path, cb)
end


function M.rename(file, new_path, cb)
  local opt = { cmd='mv', args = {file, new_path } };
  run_process(opt, 'Error renaming '..file..' to '..new_path, cb)
end

function M.create(path, file, folders, cb)
  local opt_file = nil
  local file_path = nil
  if file ~= nil then
    file_path = path..folders..file
    opt_file = { cmd='touch', args = {file_path} }
  end

  if folders ~= "" then
    local folder_path = path..folders
    local opt = {cmd = 'mkdir', args = {'-p', folder_path }}
    run_process(opt, 'Error creating folder '..folder_path, function()
      if opt_file then
        run_process(opt, 'Error creating file '..file_path, cb)
      else
        cb()
      end
    end)
  elseif opt_file then
    run_process(opt_file, 'Error creating file '..file_path, cb)
  end
end

return M
