local neogit = require("neogit")
neogit.setup({})

vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>", { silent = true, noremap = true, desc = "Git Blame" })

vim.api.nvim_create_autocmd({ "BufEnter" }, {
    callback = function()
        require("lazygit.utils").project_root_dir()
    end,
})
