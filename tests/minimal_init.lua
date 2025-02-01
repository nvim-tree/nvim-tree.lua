-- this file is necessary for the minimal_init option which directs the spawned nvim test instances be run with --noplugin

-- ensure that this nvim-tree is not overridden by installed versions in .local/share/nvim/site etc.
vim.o.runtimepath = vim.env.REPO_DIR .. "," .. vim.o.runtimepath

-- plenary will append ,.,$HOME/src/nvim-tree/master/plenary.nvim in the spawned test instances, however we want this here to prevent overrides
vim.o.runtimepath = vim.env.PLENARY_DIR .. "," .. vim.o.runtimepath

