# Generating Test Data

Execute `scripts/functionaltest.sh -l <data path>`

This will open an interactive vim session that closely matches the test headless session, using the init: `test/func/init_live.lua`

1. Perform the actions to be tested
2. Dump the screen `<leader>d` to `/tmp/live_dump.txt`
3. Add the dump to `screen:expect` `grid`, with `attr_ids = {}`

The dump will have `|` appended to each line, with a caret `^` at the cursor position.

The sessions should have screen size 80x24. Use `<leader>r` to reset the size if the terminal has changed it.

