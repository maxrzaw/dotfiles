local Persist = require("mzawisa.persist")
local M = {}
local persisted = Persist:get("formatting_enabled")
if persisted == nil then
    Persist:set("formatting_enabled", true)
end

M._formatting_enabled = Persist:get("formatting_enabled")

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

function M.formatting_enabled()
    return M._formatting_enabled
end

function M.lualine()
    if M._formatting_enabled then
        return ""
    else
        return "Formatting disabled"
    end
end

return M
