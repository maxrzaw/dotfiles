local Persist = require("mzawisa.persist")
local M = {}
local persisted = Persist:get("neotree_pinned")
if persisted == nil then
    Persist:set("neotree_pinned", false)
end

M._pinned = Persist:get("neotree_pinned")

local function sync()
    Persist:set("neotree_pinned", M._pinned)
    Persist:sync()
end

function M.pin()
    M._pinned = true
    sync()
end

function M.unpin()
    M._pinned = false
    sync()
end

function M.toggle()
    M._pinned = not M._pinned
    sync()
end

function M.pinned()
    return M._pinned
end

return M
