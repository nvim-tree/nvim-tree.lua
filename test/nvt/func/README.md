# nvim-tree Functional Testing

<!-- 
https://github.com/jonschlinkert/markdown-toc
markdown-toc -i test/nvt/func/README.md
-->

<!-- toc -->

- [Quick Start](#quick-start)
- [Overview](#overview)
  * [Test Framework](#test-framework)
  * [Directories](#directories)
    + [Logs](#logs)
  * [Execution](#execution)
- [Generating Test Data](#generating-test-data)
  * [Text Only: `attr_ids = {}`](#text-only-attr_ids--)
  * [Text And Highlight](#text-and-highlight)
- [Test Inputs](#test-inputs)
  * [Key Synchronisation](#key-synchronisation)
  * [Direct Lua Execution](#direct-lua-execution)
- [Test Assertions](#test-assertions)
  * [Screen](#screen)
    + [Highlighting: attr_ids](#highlighting-attr_ids)
    + [Grid](#grid)
      - [Text Only](#text-only)
      - [Higlighted](#higlighted)
  * [Command Line](#command-line)
  * [Messages](#messages)
  * [nvim-tree Events](#nvim-tree-events)

<!-- tocstop -->

# Quick Start

- Run the tests to ensure everything is setup: `scripts/functionaltest.sh -a` (see [Execution](#execution))
- Create a new spec file e.g. `test/nvt/func/fs/paste_spec.lua`
- Copy contents of an existing spec file to get started
- Create a new data directory e.g. `test/nvt/func/fs/paste_data` and populate it with files/directories/links
- Plan your test (see [Generating Test Data](#generating-test-data))
  - Run the live environment with `-l` e.g. `scripts/functionaltest.sh -l test/nvt/func/fs/paste_data`
  - Execute test actions, note them as `nf.feed_sync` data
  - Dump the expected screen state with `<leader>u` for use as `screen:expect` `grid`
- Build your test
  - Pass your data directory to `nf.create_session` in `before_each`
  - Pass any nvim-tree config to `nf.create_session`
  - Add `nf.feed_sync` and `n.exec_lua` (see [Test Inputs](#test-inputs))
  - Add `screen:expect` and any other asserts (see [Test Assertions](#test-assertions))
- Run your test with `-t`, (see [Execution](#execution)) e.g. `scripts/functionaltest.sh -t test/nvt/func/fs/paste_spec.lua`

# Overview

## Test Framework

Nvim's functional test framework is used. Useful references:

- `:help dev_test`
- [`test/functional/ui/screen.lua`](https://github.com/neovim/neovim/blob/master/test/functional/ui/screen.lua)

Test instances have:

- `$NVIM_TEST=1`
- `_G._nvim_test_id` set to individual test id `TXX`

Nvim sources are required by lua-language-server for test source (see [Execution](#execution)) one of:

- `$DIR_NVIM_SRC/test`
- `/tmp/src/neovim-stable/test`

## Directories

Test instances always execute under the hardcoded `/tmp/nvt_func` directory, so that assertions match that root folder. This directory is removed after test execution.

If a test data directory is passed to `test.nvt.func.fixtures` `create_session`, it will be copied to `/tmp/nvt_func/data` and the test instance will execute in that directory.

The `nvim-tree.lua` source directory is temporarily linked as `src/nvt/pack/dist/opt/nvim-tree.lua` under the Nvim source.

When running functional tests, a temporary `build/Xtest_xdg` directory is created, which contains only links to `runtime`, `src` and `test`, hence we link in a directory that is available at test time.

`src` is used instead of `test` to prevent the lua-language-server from finding it during test execution.

### Logs

When `log.enable` is set, individual test logs will be persistently located at `/tmp/nvt_test.TXX.log`, as `stdpath("log")` is removed after test execution.

## Execution

The test harness `scripts/functionaltest.sh` is used to run one or many tests or a live test instance for generating test data.

See `scripts/functionaltest.sh -h`

You will be prompted with instructions on fetching and using the Nvim sources.

`scripts/functionaltest.sh -a` executes all tests

`scripts/functionaltest.sh -t <foo_spec.lua>` executes a single test

`scripts/functionaltest.sh -t <dir>` executes all tests in a directory

# Generating Test Data

Execute `scripts/functionaltest.sh -l [ <data dir> ]`

This will open an interactive vim session that closely matches the test headless session, using the init: `test/func/init_live.lua`. Add any test specific config to `require("nvim-tree").setup` when needed.

If a `data` directory is given, it will be recursively copied to cwd `/tmp/nvt_func/data` otherwise uses empty cwd `/tmp/nvt_func`

Test's `data` directory will be used if present.

- `<Leader>u` to dump the entire screen to `/tmp/nvt_func/dump.txt` and open it
- `<Leader>r` to resize the screen to 80 x 24, to match tests
- `<Leader>o` to execute `api.tree.open()`

## Text Only: `attr_ids = {}`

1. Perform the actions to be tested
2. Dump the screen `<Leader>u` to `/tmp/nvt_func/dump.txt`
3. Add the dump to `screen:expect` `grid`, with `attr_ids = {}`

The dump will have `|` appended to each line, with a caret `^` at the cursor position.

## Text And Highlight

Additional work is required to add highlight groups.

Write the test as per Text Only and execute; it will fail.

Use `Snapshot: screen:expect([[` contents from test log as the `grid`, visually validating that it matches the screen dump.

# Test Inputs

## Key Synchronisation

The Nvim functional test framework's inputs are handled asynchronously via the commonly used `test.functional.testnvim` `feed` (non-deferred). It will execute all the inputs _immediately_ without waiting for them to complete, most notably lua callbacks such as nvim-tree mappings as well as some visual mode operations. See `:help api-fast`

Prefer `test.nvt.func.util` `feed_sync` to feed keys synchronously (deferred), blocking the test thread and instance until the instance's main loop is complete.

## Direct Lua Execution

Execute lua inside the test instance via `n.exec_lua`

# Test Assertions

## Screen

`Screen:expect` is the main assertion mechanism, validating the contents of the entire screen, message area, command line etc., 

`expect` will continually validate the contents of the screen after each update until it matches the expected. This allows for for asynchronous updates such as git/filesystem changes, however it will timeout and fail if the expected state is not reached after `timeout` ms, default 3500.

### Highlighting: attr_ids

Assertions may optionally include highlights and extmarks, referred to as `attr_ids`.

_Important_: `attr_ids = {}` should always be set when invoking `Screen:expect` except when asserting a highlighted grid. The performance impact of asserting attributes is ~8x

Nvim tests almost always asserts highlights and extmarks however they can be difficult to prepare and read. nvim-tree usually asserts only text, asserting highlights only when necessary for the test e.g. copy, git status.

Unique nvim-tree highlight groups `attr_ids` are defined during `test.nvt.func.fixtures` `create_session`. An addition variant for each group when in the cursor line suffixed with `CL` e.g. `NvimTreeFileIconCL` for file icons within the cursor line.

### Grid

#### Text Only

Set `attr_ids = {}` when calling `expect` to direct a text only assertion.

See [Generating Test Data](#generating-test-data) to dump the screen contents to a file.

Contents are inserted directly into a text block `grid` e.g.

```lua
    screen:expect({
      attr_ids = {},
      grid = [[
  /tmp/nvt_func/data/..       │                                                 |
    d1                      │~                                                |
    d2                      │~                                                |
  ^   f1                      │~                                                |
     f2                      │~                                                |
~                             │~                                                |*17
NvimTree_1 [-]                 [No Name]                                        |
[NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
    ]],
    })
```

Note the 17 repeated lines suffixed with `*17` which is optional; the entire screen may be inserted.

#### Higlighted

It is impractical to generate the `grid` manually, due to the number of `attr_ids` that must be specified, combined and turned on and off. It also has a great performance impact.

Test specific highlight groups may be added via `nf.create_session` `test.nvt.func.fixtures.HiDefs`

- Create a passing `screen:expect` with text only
- Remove `attr_ids = {}` and re-run the test
- On failure, the test will print the expected `grid` to use e.g.

```lua
Snapshot:
screen:expect([[
  {NvimTreeSignColumn:  }{NvimTreeRootFolder:/tmp/nvt_func/data/..}{NvimTreeNormal:       }{NvimTreeWinSeparator:│}                                                 |
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d1}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed: }{NvimTreeClosedFolderIcon:}{NvimTreeNormal: }{NvimTreeFolderName:d2}{NvimTreeNormal:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosedCL:^  }{NvimTreeFileIconCL:}{NvimTreeNormalCL: }{NvimTreeCopiedHLCL:f1}{NvimTreeNormalCL:                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeSignColumn:  }{NvimTreeFolderArrowClosed:  }{NvimTreeFileIcon:}{NvimTreeNormal: f2                      }{NvimTreeWinSeparator:│}{1:~                                                }|
  {NvimTreeEndOfBuffer:~                             }{NvimTreeWinSeparator:│}{1:~                                                }|*17
  {NvimTreeStatusLine:NvimTree_1 [-]                 }{2:[No Name]                                        }|
  [NvimTree] /tmp/nvt_func/data/f1 added to clipboard.                            |
]])
```

## Command Line

`Screen:expect` `cmdline` may be used to assert command line state. `test.functional.ui.screen.Opts` `ext_cmdline` must be enabled, e.g.

```lua
screen = nf.create_session({}, nil, nil, { ext_cmdline = true })
---
screen:expect({
  attr_ids = {},
  cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
})
```

## Messages

Messages may be usually be asserted simply via `Screen:expect` `grid`

In the case of complex or multiline messages, `test.functional.ui.screen.Opts` `ext_messages` may be used to capture messages for finer grained assertion. This will:

- implicitly set `ext_cmdline`
- remove the command line from the screen `grid`; which may need to be adjusted to match

e.g.
```lua
screen = nf.create_session({}, nil, nil, { ext_messages = true, })
---
screen:expect({
  attr_ids = {},
  messages = { { content = { { "[NvimTree] trash.cmd 'foobarbaz' is not an executable.", "WarningMsg" } }, history = true, kind = "echomsg" }, }
})
```

## nvim-tree Events

Specific nvim-tree events may be subscribed to via `test.nvt.func.fixtures` `event_subscribe`, recorded as `nvt.functest.event[]` and the entire collection asserted in order via `test.nvt.func.asserts` `events_received`

After assertion, the collected events are cleared.

e.g.
```lua
local Event = require("nvim-tree._meta.api.events").Event
nf.event_subscribe(Event.FileRemoved)
nf.event_subscribe(Event.WillRemoveFile)
---
na.events_received({
  { event_type = "WillRemoveFile", payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
  { event_type = "FileRemoved",    payload = { fname = "/tmp/nvt_func/data/d 1/d 1 f 1", }, },
})
```
