-- formatting
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("UserLuaFormatting", {}),
    callback = function()
        require("stylua-nvim").format_file()
    end,
})
