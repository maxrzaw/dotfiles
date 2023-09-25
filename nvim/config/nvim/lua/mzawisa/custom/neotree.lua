local M = {}
M._pinned = false

function M.pin()
    M._pinned = true
end

function M.unpin()
    M._pinned = false
end

function M.pinned()
    return M._pinned
end

return M
