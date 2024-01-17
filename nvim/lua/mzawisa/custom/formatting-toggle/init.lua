local Persist = require("mzawisa.persist")
local M = {}
local persisted = Persist:get("formatting_enabled")
if persisted == nil then
    Persist:set("formatting_enabled", true)
end

--- Is Formatting enabled?
---@type boolean
M._formatting_enabled = Persist:get("formatting_enabled") or false

---@type string[]
M._ignore_paths = {}

--- Add Paths to the list of paths that should not be formatted when paths are checked
---@param paths string[]
function M.add_ignore_paths(paths)
    for _, path in ipairs(paths) do
        table.insert(M._ignore_paths, path)
    end
end

local function sync()
    Persist:set("formatting_enabled", M._formatting_enabled)
    Persist:sync()
end

function M.disable()
    M._formatting_enabled = false
    sync()
end

function M.enable()
    M._formatting_enabled = true
    sync()
end

function M.toggle()
    M._formatting_enabled = not M._formatting_enabled
    if M._formatting_enabled then
        vim.notify("Formatting enabled", vim.log.levels.INFO)
    else
        vim.notify("Formatting disabled", vim.log.levels.INFO)
    end
    sync()
end

--- Is formatting enabled?
---@param path string? Optional parameter to check if formatting is disabled for a specific path
---@return boolean
function M.formatting_enabled(path)
    local enabled = M._formatting_enabled
    if path ~= nil and enabled then
        for _, p in ipairs(M._ignore_paths) do
            if string.find(path, p) then
                enabled = false
                break
            end
        end
    end
    return enabled
end

function M.lualine()
    if M._formatting_enabled then
        return ""
    else
        return "Formatting disabled"
    end
end

return M
