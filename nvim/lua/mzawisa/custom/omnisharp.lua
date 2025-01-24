local telescope_builtin = require("telescope.builtin")
local M = {}

local function is_omnisharp_active_in_buffer()
    local lsp_clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    for _, c in pairs(lsp_clients) do
        if c.name == "omnisharp" then
            return true
        end
    end
    return false
end

function M.lsp_definitions()
    if is_omnisharp_active_in_buffer() then
        require("omnisharp_extended").telescope_lsp_definition()
    else
        telescope_builtin.lsp_definitions()
    end
end

function M.lsp_references()
    if is_omnisharp_active_in_buffer() then
        require("omnisharp_extended").telescope_lsp_references(require("telescope.themes").get_ivy({
            excludeDefinition = true,
            show_line = false,
            initial_mode = "normal",
        }))
    else
        telescope_builtin.lsp_references()
    end
end

function M.lsp_type_definitions()
    if is_omnisharp_active_in_buffer() then
        require("omnisharp_extended").telescope_lsp_type_definition()
    else
        telescope_builtin.lsp_type_definitions()
    end
end

function M.lsp_implementations()
    if is_omnisharp_active_in_buffer() then
        require("omnisharp_extended").telescope_lsp_implementation()
    else
        telescope_builtin.lsp_implementations()
    end
end

return M
