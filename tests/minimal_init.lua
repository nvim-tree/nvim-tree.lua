-- Prepend these as plenary appends a "." and plenary directory
-- The spawned processes don't specify --clean so contain the full ~/.local runtime path
vim.o.runtimepath = string.format(
  "%s,%s,%s",
  vim.env.DIR_REPO,
  vim.env.DIR_PLENARY,
  vim.o.runtimepath
)
