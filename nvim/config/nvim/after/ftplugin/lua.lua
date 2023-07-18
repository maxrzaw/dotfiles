-- formatting
vim.api.nvim_create_autocmd("BufWritePre", {
    desc = "Format lua on write using stylua",
    group = vim.api.nvim_create_augroup("UserLuaFormatting", { clear = true }),
    callback = function(opts)
        if vim.bo[opts.buf].filetype == "lua" then
            require("stylua-nvim").format_file({ error_display_strategy = "none" })
        end
    end,
})
