return {
    {
        "stevearc/conform.nvim",
        opts = {
            format_on_save = function(bufnr)
                local path = vim.api.nvim_buf_get_name(bufnr)
                if not require("mzawisa.custom.formatting-toggle").formatting_enabled(path) then
                    return
                end
                return { timeout_ms = 500 }
            end,
            default_format_opts = {
                lsp_format = "fallback",
            },
            formatters = {
                csharpier = {
                    command = "dotnet",
                    -- prepend_args = { "csharpier", "format" }, -- This is for version 1.0.0
                    prepend_args = { "csharpier" },
                },
            },
            formatters_by_ft = {
                lua = { "stylua" },
                cs = { "csharpier", lsp_format = "first" },
            },
        },
    },
}
