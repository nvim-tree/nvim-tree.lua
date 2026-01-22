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
- [Documentation](#documentation)
  * [Config And Mappings](#config-and-mappings)
  * [API](#api)
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
1. Runs `scripts/doc-comments.sh` to validate annotated documentation

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

If `lua-language-server` is not available or `--check` doesn't function (e.g. Arch Linux 3.9.1-1) you can manually install it as per `ci.yml` e.g.

```sh
mkdir luals
curl -L "https://github.com/LuaLS/lua-language-server/releases/download/3.9.1/lua-language-server-3.9.1-linux-x64.tar.gz" | tar zx --directory luals

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

# Documentation

## Config And Mappings

When adding to or changing:
1. Default config
2. `config` classes
3. `on_attach` default mappings

You must generate help documentation. This requires neovim stable sources. You will be promted with instructions on fetching and referencing the source.

```sh
make help-update
```

This will:
1. Update config defaults in `*nvim-tree-setup*`
2. Regenerate from `*nvim-tree-config*` to the end of the file, see `gen_vimdoc.sh`
3. Update default mappings in `*nvim-tree-mappings-default*` and `*nvim-tree-quickstart-help*`

Commit or stage your changes then run:
```sh
make help-check
```

This will re-run `help-update` and check that there are no diffs. It will also lint the documentation, see `lintdoc.sh`

## API

When adding or changing API please update :help nvim-tree-api

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
