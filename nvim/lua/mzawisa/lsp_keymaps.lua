local get_opts = require("mzawisa.keymap").get_opts
local omnisharp_custom = require("mzawisa.custom.omnisharp")
local M = {}
M.bordered_hover = function(_opts)
    _opts = _opts or {}
    return vim.lsp.buf.hover(vim.tbl_extend("force", { border = "rounded" }, _opts))
end
M.bordered_signature_help = function(_opts)
    _opts = _opts or {}
    return vim.lsp.buf.signature_help(vim.tbl_extend("force", { border = "rounded" }, _opts))
end
M.set_default_lsp_keybindings = function()
    vim.keymap.set("n", "gt", omnisharp_custom.lsp_type_definitions, get_opts("LSP: [G]o to [T]ype Definitions"))
    vim.keymap.set("n", "gd", omnisharp_custom.lsp_definitions, get_opts("LSP: [G]o to [D]efinitions"))
    vim.keymap.set("n", "gr", omnisharp_custom.lsp_references, get_opts("LSP: [G]o to [R]eferences"))
    vim.keymap.set("n", "gi", omnisharp_custom.lsp_implementations, get_opts("LSP: [G]o to [I]mplementations"))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, get_opts("LSP: [G]o to [D]eclaration"))

    vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, get_opts("LSP: [V]iew [D]iagnostics for current line"))
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, get_opts("LSP: [C]ode [A]ction"))
    vim.keymap.set("n", "<leader>dn", function()
        vim.diagnostic.jump({ count = 1, float = true })
    end, get_opts("LSP: Go To [N]ext [D]iagnostic"))
    vim.keymap.set("n", "<leader>dN", function()
        vim.diagnostic.jump({ count = -1, float = true })
    end, get_opts("LSP: Go To Prev [D]iagnostic"))
    vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<CR>", get_opts("LSP: [L]ist All [D]iagnostics"))
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, get_opts("LSP: [R]ename Symbol"))
    vim.keymap.set("i", "<C-h>", function()
        M.inlay_hints_enabled = not M.inlay_hints_enabled
        vim.lsp.inlay_hint.enable(M.inlay_hints_enabled)
    end, get_opts("LSP: Toggle Inlay [H]ints"))
    vim.keymap.set("n", "<C-h>", function()
        M.inlay_hints_enabled = not M.inlay_hints_enabled
        vim.lsp.inlay_hint.enable(M.inlay_hints_enabled)
    end, get_opts("LSP: Toggle Inlay [H]ints"))
    vim.keymap.set("i", "<C-k>", M.bordered_signature_help, get_opts("LSP: Signature Help"))
    vim.keymap.set("n", "K", M.bordered_hover, get_opts("LSP: Hover"))
end
M.set_default_lsp_keybindings()
return M
