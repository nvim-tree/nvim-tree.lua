local test_harness = require('plenary.test_harness')

local DIR_TEST = vim.env.DIR_REPO .. '/tests'
local FILE_MINIMAL_INIT = DIR_TEST .. '/minimal_init.lua'

test_harness.test_directory(DIR_TEST, { minimal_init = FILE_MINIMAL_INIT })

