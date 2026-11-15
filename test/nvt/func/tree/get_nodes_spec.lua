local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local nf = require("test.nvt.func.fixtures")

-- 0.12 global compatibility
---@diagnostic disable-next-line: inject-field, undefined-global
t.describe, t.it, t.before_each = t.describe or describe, t.it or it, t.before_each or before_each


t.before_each(function()
  nf.create_session({
    data = "test/nvt/func/tree/get_nodes_data",
  })
end)


t.describe("tree.get_nodes", function()
  t.it("all types", function()
    n.exec_lua(function()
      local api = require("nvim-tree.api")
      api.tree.open()
      api.tree.expand_all()

      local root = assert(api.tree.get_nodes())

      ---@type Explorer
      local explorer = assert(require("nvim-tree.core").get_explorer())

      -- root
      assert(root:is(api.RootNode))
      assert(root:is(api.DirectoryNode))
      assert(root.type == "directory")
      assert(root.absolute_path == "/tmp/nvt_func/data")
      assert(#root.nodes == 3)
      local internal = assert(explorer:node_with_uid_node(root))
      assert(internal.absolute_path == "/tmp/nvt_func/data")

      -- normal directory
      local d1 = root.nodes[1]
      assert(d1:is(api.DirectoryNode))
      assert(d1.type == "directory")
      assert(d1.absolute_path == "/tmp/nvt_func/data/d1")
      assert(#d1.nodes == 1)
      internal = assert(explorer:node_with_uid_node(d1))
      assert(internal.absolute_path == "/tmp/nvt_func/data/d1")

      -- normal file
      local d1f1 = d1.nodes[1]
      assert(d1f1:is(api.FileNode))
      assert(d1f1.type == "file")
      assert(d1f1.absolute_path == "/tmp/nvt_func/data/d1/d1f1")
      internal = assert(explorer:node_with_uid_node(d1f1))
      assert(internal.absolute_path == "/tmp/nvt_func/data/d1/d1f1")

      -- linked file
      local d1f1link = root.nodes[3]
      assert(d1f1link:is(api.FileNode))
      assert(d1f1link:is(api.FileLinkNode))
      assert(d1f1link:is(api.LinkNode))
      assert(d1f1link.type == "link")
      assert(d1f1link.absolute_path == "/tmp/nvt_func/data/d1f1link")
      assert(d1f1link.link_to == "/tmp/nvt_func/data/d1/d1f1")
      internal = assert(explorer:node_with_uid_node(d1f1link))
      assert(internal.absolute_path == "/tmp/nvt_func/data/d1f1link")

      -- linked directory
      local d1link = root.nodes[2]
      assert(d1link:is(api.LinkNode))
      assert(d1link:is(api.DirectoryLinkNode))
      assert(d1link.type == "link")
      assert(d1link.absolute_path == "/tmp/nvt_func/data/d1link")
      assert(d1link.link_to == "/tmp/nvt_func/data/d1")
      print(#d1link.nodes)
      assert(#d1link.nodes == 1)
      internal = assert(explorer:node_with_uid_node(d1link))
      assert(internal.absolute_path == "/tmp/nvt_func/data/d1link")

      -- linked directory file
      local d1f1_linked = d1link.nodes[1]
      assert(d1f1_linked:is(api.FileNode))
      assert(d1f1_linked.type == "file")
      assert(d1f1_linked.absolute_path == "/tmp/nvt_func/data/d1/d1f1")
      internal = assert(explorer:node_with_uid_node(d1f1_linked))
      assert(internal.absolute_path == "/tmp/nvt_func/data/d1/d1f1")
    end)
  end)
end)

-- vim:colorcolumn=80
