# Contributing to `nvim-tree.lua`

Thank you for contributing.

## Styling and formatting

Code is formatted using luacheck, and linted using stylua.
You can install these with:

```bash
luarocks install luacheck
cargo install stylua
```

## Adding new actions

To add a new action, add a file in `actions/name-of-the-action.lua`. You should export a `setup` function if some configuration is needed.
Once you did, you should run the `scripts/update-help.sh`.

## Documentation

When adding new options, you should declare the defaults in the main `nvim-tree.lua` file.
Once you did, you should run the `scripts/update-help.sh`.

Documentation for options should also be added, see how this is done after `nvim-tree.disable_netrw` in the `nvim-tree-lua.txt` file.
