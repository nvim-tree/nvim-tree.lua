local api = {}

--
-- Load the (empty) meta definitions
--
api.commands = require("nvim-tree._meta.api.commands")
api.events = require("nvim-tree._meta.api.events")
api.filter = require("nvim-tree._meta.api.filter")
api.fs = require("nvim-tree._meta.api.fs")
api.health = require("nvim-tree._meta.api.health")
api.map = require("nvim-tree._meta.api.map")
api.marks = require("nvim-tree._meta.api.marks")
api.node = require("nvim-tree._meta.api.node")
api.tree = require("nvim-tree._meta.api.tree")

--
-- Map implementations
--
require("nvim-tree.api.impl.pre")(api)

return api
