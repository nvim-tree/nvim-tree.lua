# Overview

## Test Framework

TODO

## Directories

Test instances always execute under the hardcoded `/tmp/nvt_func` directory, so that assertions match that root folder.

If a test data directory is passed to `test.nvt.func.fixtures` `create_session`, it will be copied to `/tmp/nvt_func/data` and the test instance will execute in that directory.

The `nvim-tree.lua` source directory is temporarily linked as `src/nvt/pack/dist/opt/nvim-tree.lua` under the Nvim source.

When running functional tests, a temporary `build/Xtest_xdg` directory is created, which contains only links to `runtime`, `src` and `test`, hence we link in a directory that is available at test time.

`src` is used instead of `test` to prevent your lua-language-server from finding it during test execution.

## Execution

The test harness `scripts/functionaltest.sh` is used to run one or many tests or a live test instance for generating test data.

Nvim sources are required. You will be prompted with instructions on fetching and using the sources.

# Generating Test Data

Execute `scripts/functionaltest.sh -l [ <data dir> ]`

This will open an interactive vim session that closely matches the test headless session, using the init: `test/func/init_live.lua`. Add any test specific config to `require("nvim-tree").setup` when needed.

If a `data` directory is given, it will be recursively copied to cwd `/tmp/nvt_func/data` otherwise uses empty cwd `/tmp/nvt_func`

Test's `data` directory will be used if present.

- `<Leader>u` to dump the entire screen to `/tmp/nvt_func/dump.txt` and open it
- `<Leader>c` to dump with identical lines collapsed
- `<Leader>r` to resize the screen to 80 x 24, to match tests
- `<Leader>o` to execute `api.tree.open()`

## Text Only: `attr_ids = {}`

1. Perform the actions to be tested
2. Dump the screen `<Leader>u` or `<Leader>c>` to `/tmp/nvt_func/dump.txt`
3. Add the dump to `screen:expect` `grid`, with `attr_ids = {}`

The dump will have `|` appended to each line, with a caret `^` at the cursor position.

## Text And Highlight

Additional work is required to add highlight groups.

Write the test as per Text Only and execute; it will fail.

Use `Snapshot: screen:expect([[` contents from test log as the `grid`, visually validating that it matches the screen dump.

# Test Inputs

## Synchronisation

The Nvim functional test framework's inputs are handled asynchronously via the commonly used `test.functional.testnvim` `feed` (non-deferred). It will execute all the inputs _immediately_ without waiting for them to complete, most notably lua callbacks such as nvim-tree mappings as well as some visual mode operations. See `:help api-fast`

Prefer `test.nvt.func.util` `feed_sync` to feed keys synchronously (deferred), blocking the test thread and instance until the instance's main loop is complete.

# Test Assertions

## Screen Grid

`Screen:expect` `grid` is the main assertion mechanism, validating the contents of the entire screen, optionally including highlights and extmarks, referred to as `attr_ids`.

Nvim tests almost always asserts highlights and extmarks however they can be difficult to prepare and read. nvim-tree usually asserts only text, asserting highlights only when necessary for the test e.g. copy, git status.

Unique nvim-tree highlight groups `attr_ids` are defined during `test.nvt.func.fixtures` `create_session`. An addition variant for each group when in the cursor line suffixed with `CL` e.g. `NvimTreeFileIconCL` for file icons within the cursor line.

`expect` will continually validate the contents of the screen after each update until it matches the expected. This allows for for asynchronous updates such as git/filesystem changes, however it will timeout and fail if the expected state is not reached after `timeout` ms, default 3500.

### Text Only

Set `attr_ids = {}` when calling `expect` to direct a text only assertion.

See [Generating Test Data](TODO link) to dump the screen contents to a file.

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

### Complete

It is impractical to generate the `grid` manually, due to the number of `attr_ids` that must be specified, combined and turned on and off.

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
  cmdline = { { prompt = "Create ", content = { { "/tmp/nvt_func/data/" } }, pos = 19, } },
})
```

## Messages

Messages may be usually be asserted simply via `Screen:expect` `grid`

In the case of complex or multiline messages, `test.functional.ui.screen.Opts` `ext_messages` may be used to capture messages for finer grained assertion. This will:

- implicitly set `ext_cmdline`
- remove the command line from the screen `grid`; which you may need to adjust to match

e.g.
```lua
screen = nf.create_session({}, nil, nil, { ext_messages = true, })
---
screen:expect({
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
