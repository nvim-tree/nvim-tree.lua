# Contributing to `nvim-tree.lua`

Thank you for contributing.

See [wiki: Development](https://github.com/nvim-tree/nvim-tree.lua/wiki/Development) for environment setup, tips and tools.

<!-- 
https://github.com/jonschlinkert/markdown-toc
markdown-toc --maxdepth=2 -i CONTRIBUTING.md
-->

<!-- toc -->

- [Tools](#tools)
- [Quality](#quality)
  * [lint](#lint)
  * [style](#style)
  * [check](#check)
- [Diagnostics](#diagnostics)
- [Backwards Compatibility](#backwards-compatibility)
- [:help Documentation](#help-documentation)
  * [Generated Content](#generated-content)
  * [Updating And Generating](#updating-and-generating)
  * [Checking And Linting](#checking-and-linting)
- [Windows](#windows)
- [Pull Request](#pull-request)
  * [Subject](#subject)

<!-- tocstop -->

# Tools

Following are used during CI and strongly recommended during local development.

Language server: [luals](https://luals.github.io)

Lint: [luacheck](https://github.com/lunarmodules/luacheck/)

Style Fixing: [EmmyLuaCodeStyle](https://github.com/CppCXY/EmmyLuaCodeStyle): `CodeCheck`

nvim-tree.lua migrated from stylua to EmmyLuaCodeStyle ~2024/10. `vim.lsp.buf.format()` may be used as it is the default formatter for luals, using an embedded [EmmyLuaCodeStyle](https://github.com/CppCXY/EmmyLuaCodeStyle)

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

1. Runs lua language server `codestyle-check` only, using `.luarc.json` settings
1. Runs `scripts/doc-comments.sh` to normalise annotated documentation

```sh
make style
```

You can automatically fix style issues using `CodeCheck`:

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

If `lua-language-server` is not available or `--check` doesn't function (e.g. Arch Linux 3.9.1-1) you can manually install it as per `ci.yml` using its current `luals_version` e.g.

```sh
mkdir luals
curl -L "https://github.com/LuaLS/lua-language-server/releases/download/3.15.0/lua-language-server-3.15.0-linux-x64.tar.gz" | tar zx --directory luals

PATH="luals/bin:${PATH}" make check
```

# Diagnostics

Diagnostics issues may not be suppressed. See [luals](https://luals.github.io) documentation for details on how to structure the code and comments.

Suppressions are permitted only in the following cases:

- Backwards compatibility shims
- neovim API metadata incorrect, awaiting upstream fix
- classic class framework

# Backwards Compatibility

Whenever new neovim API is introduced, please ensure that it is available in older versions. See `:help deprecated.txt` and `$VIMRUNTIME/lua/vim/_meta/api.lua`

See `nvim-tree.setup` for the oldest supported version of neovim. If the API is not availble in that version, a backwards compatibility shim must be used e.g.

```lua
if vim.fn.has("nvim-0.10") == 1 then
  modified = vim.api.nvim_get_option_value("modified", { buf = target_bufid })
else
  modified = vim.api.nvim_buf_get_option(target_bufid, "modified") ---@diagnostic disable-line: deprecated
end
```

# :help Documentation

Please update or add to `doc/nvim-tree-lua.txt` as needed.

## Generated Content

`doc/nvim-tree-lua.txt` content starting at `*nvim-tree-config*` will be replaced with generated content. Do not manually edit that content.

### API and Config

Help is generated for:
- `nvim_tree.config` classes from `lua/nvim-tree/_meta/config/`
- `nvim_tree.api` functions from `lua/nvim-tree/_meta/api/`

Please add or update documentation when you make changes, see `:help dev-lua-doc` for docstring format.

`scripts/gen_vimdoc_config.lua` contains the manifest of help sources.

### Config And Mappings

Help is updated for:
- Default keymap at `keymap.on_attach_default`
- Default config at `--- default-config-start`

## Updating And Generating

Nvim sources are required. You will be prompted with instructions on fetching and using the sources.

See comments at the start of each script for complete details.

```sh
make help-update
```

- `scripts/help-update.sh`
  - Update config defaults `*nvim-tree-setup*`
  - Update default mappings:
    - `*nvim-tree-mappings-default*`
    - `*nvim-tree-quickstart-help*`

- `scripts/gen_vimdoc.sh`
  - Remove content starting at `*nvim-tree-config*`
  - Generate config classes `*nvim-tree-config*`
  - Generate API `*nvim-tree-api*`

## Checking And Linting

This is run in CI. Commit or stage your changes and run:

```sh
make help-check
```

- Re-runs `make help-update`
- Checks that `git diff` is empty, to ensure that all content has been generated. This is why a stage or commit is necessary.
- Lints `doc/nvim-tree-lua.txt` using `scripts/lintdoc.sh` to check for no broken links etc.

# Windows

Please note that nvim-tree team members do not have access to nor expertise with Windows.

You will need to be an active participant during development and raise a PR to resolve any issues that may arise.

Please ensure that windows specific features and fixes are behind the appropriate feature flag, see [wiki: OS Feature Flags](https://github.com/nvim-tree/nvim-tree.lua/wiki/Development#os-feature-flags)

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
