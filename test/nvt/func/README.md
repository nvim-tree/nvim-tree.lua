# Generating Test Data

Execute `scripts/functionaltest.sh -l [ <file or dir> ]`

This will open an interactive vim session that closely matches the test headless session, using the init: `test/func/init_live.lua`. Add any test specific config to `require("nvim-tree").setup` when needed.

If a `data` directory is present, it will be copied and the session will execute in `/tmp/nvt_func/data` otherwise `/tmp/nvt_func`.

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

TODO: how to handle asynchronous operations e.g. fs/git update

## Synchronisation

The Nvim functional test framework's inputs are handled asynchronously via the commonly used `test.functional.testnvim` `feed` (non-deferred). It will execute all the inputs _immediately_ without waiting for them to complete, most notably lua callbacks such as nvim-tree mappings as well as some visual mode operations. See `:help api-fast`

Prefer `test.nvt.func.util` `feed_sync` to feed keys synchronously (deferred), blocking the test thread and instance until the instance's main loop is complete.

# Test Mechanisms

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

