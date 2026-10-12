# Generating Test Data

Execute `scripts/functionaltest.sh -l [ <data dir> ]`

This will open an interactive vim session that closely matches the test headless session, using the init: `test/func/init_live.lua`

Test's `data` directory should be specified if present.

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

TODO: this isn't great and results in a lot of test boilerplate; maybe write a `feed_sync` util, if there is not anything available
TODO: how to handle asynchronous operations e.g. fs/git update

### `feed()`

`test.functional.testnvim` `feed` is asynchronous and does not block the test thread: all inputs are all sent consecutively via `nvim_input()` and the function returns immediately. Nvim will effectively execute each input synchronously when the input blocks the main loop i.e. no threads or processes spawned.

Before asserts, `screen:expect` etc., `poke_eventloop()` should be called, to ensure that all inputs have been processed by the main loop.

_Exception:_ visual operations (e.g. select multiple for copy) do not appear to be executed synchronously. `poke_eventloop()` after those inputs to ensure synchronisation.

### `exec_lua()`

`test.functional.testnvim` `exec_lua` is synchronous: it will block the test thread until completion.

