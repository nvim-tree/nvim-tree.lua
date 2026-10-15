local n = require("test.functional.testnvim")()

local M = {}


---Feed keys synchronously (deferred), blocking the test thread and instance until the instance's main loop is complete.
---This is needed as api-fast input will execute lua callbacks (such as nvim-tree mappings) then execute the next input without waiting for the callback to complete.
---Calls feedkeys() (non-deferred, api-fast) then poke_eventloop() for each input passed.
---See :help api-fast
---@param inputs string[]
function M.feed_sync(inputs)
  for _, v in ipairs(inputs) do
    -- api-fast, does not wait for callbacks or input to complete
    n.feed(v)

    -- defer until complete
    -- n.poke_eventloop()
  end
end

return M
