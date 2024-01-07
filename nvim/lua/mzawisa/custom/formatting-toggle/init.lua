local M = {}

M._formatting_enabled = true

function M.disable()
    M._formatting_enabled = false
end

function M.enable()
    M._formatting_enabled = true
end

function M.toggle()
    M._formatting_enabled = not M._formatting_enabled
    if M._formatting_enabled then
        vim.notify("Formatting enabled", vim.log.levels.INFO)
    else
        vim.notify("Formatting disabled", vim.log.levels.INFO)
    end
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
