local prettier = { "prettierd", "prettier", stop_after_first = true }
return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo", "Format" },
        config = function()
            vim.api.nvim_create_user_command("Format", function(args)
                local range = nil
                if args.count ~= -1 then
                    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
                    range = {
                        start = { args.line1, 0 },
                        ["end"] = { args.line2, end_line:len() },
                    }
                end
                require("conform").format({ async = true, lsp_format = "fallback", range = range })
            end, { range = true })

            ---@module "conform"
            ---@type conform.setupOpts
            local opts = {
                format_on_save = function(bufnr)
                    local path = vim.api.nvim_buf_get_name(bufnr)
                    if not require("mzawisa.custom.formatting-toggle").formatting_enabled(path) then
                        return
                    end
                    return { timeout_ms = 5000 }
                end,
                default_format_opts = {
                    lsp_format = "fallback",
                    stop_after_first = true,
                },
                formatters = {
                    csharpier = {
                        command = "dotnet",
                        -- prepend_args = { "csharpier", "format" }, -- This is for version 1.0.0
                        prepend_args = { "csharpier" },
                    },
                },
                formatters_by_ft = {
                    cs = { "csharpier", lsp_format = "first", stop_after_first = false },
                    lua = { "stylua" },
                    python = { "black" },
                    rust = { "rustfmt" },
                    go = { "gofmt" },
                    terraform = { "terraform_fmt" },
                    ["terraform-vars"] = { "terraform_fmt" },
                    typescript = prettier,
                    javascript = prettier,
                    html = prettier,
                    scss = prettier,
                    json = prettier,
                    jsonc = prettier,
                    markdown = prettier,
                    yaml = prettier,
                    yml = prettier,
                },
            }
            require("conform").setup(opts)
        end,
    },
}
