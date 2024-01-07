return {
    {
        "ckipp01/stylua-nvim",
        cond = not vim.g.vscode,
        build = { "npm install -g @johnnymorganz/stylua-bin" },
        config = function()
            local formatting_toggle = require("mzawisa.custom.formatting-toggle")
            require("stylua-nvim").setup({})

            -- create an autogroup for prettier and then create an autocmd that will run prettier on save
            local group = vim.api.nvim_create_augroup("Formatting", {
                clear = false,
            })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = group,
                pattern = "*.lua",
                desc = "Run StyLua on save",
                callback = function()
                    if formatting_toggle.formatting_enabled() then
                        require("stylua-nvim").format_file({ error_display_strategy = "none" })
                    end
                end,
            })
            vim.keymap.set("n", "<leader>ft", function()
                formatting_toggle.toggle()
                require("lualine").refresh()
            end, { silent = true })
        end,
    },
}
