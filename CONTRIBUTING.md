# Contributing to `nvim-tree.lua`

Thank you for contributing.

See [Development](https://github.com/nvim-tree/nvim-tree.lua/wiki/Development) for environment setup, tips and tools.

## Styling and formatting

Code is formatted using luacheck, and linted using stylua.
You can install these with:

```bash
luarocks install luacheck
cargo install stylua
```

You can setup the git hooks by running `scripts/setup-hooks.sh`.

## Adding new actions

To add a new action, add a file in `actions/name-of-the-action.lua`. You should export a `setup` function if some configuration is needed.
Once you did, you should run the `scripts/update-help.sh`.

## Documentation

When adding new options, you should declare the defaults in the main `nvim-tree.lua` file.
Once you did, you should run the `scripts/update-help.sh`.

Documentation for options should also be added to `nvim-tree-opts` in `doc/nvim-tree-lua.txt`

## Pull Request

Please reference any issues in the description e.g. "resolves #1234".

Please check "allow edits by maintainers" to allow nvim-tree developers to make small changes such as documentation tweaks.

A test case to reproduce the issue is required. A ["Clean Room" Replication](https://github.com/nvim-tree/nvim-tree.lua/wiki/Troubleshooting#clean-room-replication) is preferred.

