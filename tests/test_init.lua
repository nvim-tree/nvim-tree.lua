local test_harness = require("plenary.test_harness")

test_harness.test_directory(
  vim.env.TEST_NAME,
  {
    minimal_init = vim.env.DIR_REPO .. "/tests/minimal_init.lua",
    sequential = true,
  }
)
