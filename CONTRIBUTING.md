# Contributing to `nvim-tree.lua`

Thank you for contributing.

See [Development](https://github.com/nvim-tree/nvim-tree.lua/wiki/Development) for environment setup, tips and tools.

# Tools

Following are used during CI and strongly recommended during local development.

Lint: [luacheck](https://github.com/lunarmodules/luacheck/)

Style: [StyLua](https://github.com/JohnnyMorganz/StyLua)

Language server: [luals](https://luals.github.io)

You can install them via you OS package manager e.g. `pacman`, `brew` or other via other package managers such as `cargo` or `luarocks`

# Quality

The following quality checks are mandatory and are performed during CI. They run on the entire `lua` directory and return 1 on any failure.

You can run them all via `make` or `make all`

You can setup git hooks to run all checks by running `scripts/setup-hooks.sh`

## lint

1. Runs luacheck quietly using `.luacheck` settings

```sh
make lint
```

## style

1. Runs stylua using `.stylua.toml` settings
1. Runs `scripts/doc-comments.sh` to validate annotated documentation

```sh
make style
```

You can automatically fix stylua issues via:

```sh
make style-fix
```

## check

1. Runs the checks that the LSP lua language server runs inside nvim using `.luarc.json` via `scripts/luals-check.sh`

```sh
make check
```

Assumes `$VIMRUNTIME` is `/usr/share/nvim/runtime`. Adjust as necessary e.g.

```sh
VIMRUNTIME="/my/path/to/runtime" make check
```

# Adding New Actions

To add a new action, add a file in `actions/name-of-the-action.lua`. You should export a `setup` function if some configuration is needed.

Once you did, you should run `make help-update`

# Documentation

## Opts

When adding new options, you should declare the defaults in the main `nvim-tree.lua` file.

Documentation for options should also be added to `nvim-tree-opts` in `doc/nvim-tree-lua.txt`

## API

When adding or changing API please update :help nvim-tree-api

# Pull Request

Please reference any issues in the description e.g. "resolves #1234", which will be closed upon merge.

Please check "allow edits by maintainers" to allow nvim-tree developers to make small changes such as documentation tweaks.

## Subject

The merge commit message will be the subject of the PR.

A [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0) subject will be validated by the Semantic Pull Request Subject CI job. Reference the issue to be used in the release notes e.g.

`fix(#2395): marks.bulk.move defaults to directory at cursor`

Available types:
* feat: A new feature
* fix: A bug fix
* docs: Documentation only changes
* style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
* refactor: A code change that neither fixes a bug nor adds a feature
* perf: A code change that improves performance
* test: Adding missing tests or correcting existing tests
* build: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
* ci: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
* chore: Other changes that don't modify src or test files
* revert: Reverts a previous commit

If in doubt, look at previous commits.

See also [The Conventional Commits ultimate cheatsheet](https://gist.github.com/gabrielecanepa/fa6cca1a8ae96f77896fe70ddee65527)
