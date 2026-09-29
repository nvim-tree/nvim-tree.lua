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

