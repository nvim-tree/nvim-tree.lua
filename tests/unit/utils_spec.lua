---@type Luassert
local assert = require("luassert")
local stub = require("luassert.stub")

local utils = require("nvim-tree.utils")

describe("utils.path_add_trailing", function()
  before_each(function()
  end)

  it("trailing added", function()
    assert.equals("foo/", utils.path_add_trailing("foo"))
  end)

  it("trailing already present", function()
    assert.equals("foo/", utils.path_add_trailing("foo/"))
  end)
end)

describe("utils.canonical_path", function()
  before_each(function()
    stub(vim.fn, "has")
  end)

  after_each(function()
  end)

  it("is windows", function()
    vim.fn.has.on_call_with("win32unix").returns(1)
    assert.equals("C:\\foo\\bar", utils.canonical_path("c:\\foo\\bar"), "should be uppercase drive")
  end)

  it("not windows", function()
    assert.equals("c:\\foo\\bar", utils.canonical_path("c:\\foo\\bar"))
  end)
end)
