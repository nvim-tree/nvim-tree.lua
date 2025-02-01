---@type Luassert
local assert = require("luassert")

local utils = require("nvim-tree.utils")

describe("utils.path_add_trailing", function()
  before_each(function()
  end)

  it("trailing added", function()
    assert.equals(utils.path_add_trailing("foo"), "foo/")
  end)

  it("trailing already present", function()
    assert.equals(utils.path_add_trailing("foo/"), "foo/")
  end)
end)
