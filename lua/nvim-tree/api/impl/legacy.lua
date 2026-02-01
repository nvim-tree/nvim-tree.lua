local M = {}

---Silently create new api entries pointing legacy functions to current
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate(api)
  api.config = api.config or {}
  api.config.mappings = api.config.mappings or {}
  api.config.mappings.get_keymap = api.map.keymap.current
  api.config.mappings.get_keymap_default = api.map.keymap.default
  api.config.mappings.default_on_attach = api.map.on_attach.default

  api.live_filter = api.live_filter or {}
  api.live_filter.start = api.filter.live.start
  api.live_filter.clear = api.filter.live.clear

  api.tree = api.tree or {}
  api.tree.toggle_enable_filters = api.filter.toggle
  api.tree.toggle_gitignore_filter = api.filter.git.ignored.toggle
  api.tree.toggle_git_clean_filter = api.filter.git.clean.toggle
  api.tree.toggle_no_buffer_filter = api.filter.no_buffer.toggle
  api.tree.toggle_custom_filter = api.filter.custom.toggle
  api.tree.toggle_hidden_filter = api.filter.dotfiles.toggle
  api.tree.toggle_no_bookmark_filter = api.filter.no_bookmark.toggle

  api.diagnostics = api.diagnostics or {}
  api.diagnostics.hi_test = api.health.hi_test

  api.decorator.UserDecorator = api.Decorator
end

return M
