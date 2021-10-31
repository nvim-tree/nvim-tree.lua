local M = {}

local sep = "/"
local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win32unix') == 1
if is_windows == true then
    sep = "\\"
end

local split_path = function(s)
    local fields = {}

    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end

local append_paths_of_buffer = function (buf_number, path_set)
    local buf_name = vim.api.nvim_buf_get_name(buf_number)
    local path_parts = split_path(buf_name)
    local parent_name = ""
    for _, part in ipairs(path_parts) do
        if parent_name:len() > 0 then
            parent_name = parent_name .. sep .. part
        else
            if is_windows then
                parent_name = part
            else
                parent_name = sep .. part
            end
        end
        path_set[parent_name] = true
    end
end

---Get a table of all open buffers, along with all parent paths of those buffers.
---The paths are the keys of the table, and all the values are 'true'.
M.get_open_buffer_paths = function ()
    local path_set = {}
    local bufs = vim.api.nvim_list_bufs()
    for _, b in ipairs(bufs) do
        if vim.api.nvim_buf_is_loaded(b) then
            append_paths_of_buffer(b, path_set)
        end
    end
    return path_set
end

--print(vim.inspect(M.get_open_buffer_paths()))
return M
