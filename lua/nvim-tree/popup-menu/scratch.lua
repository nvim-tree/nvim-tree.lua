function t()
  for _,v in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(v):match 'NvimTree' ~= nil then
      print('found!', v)
    end
  end
end
