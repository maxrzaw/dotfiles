local neogit = require("neogit")
local nnoremap = require("mzawisa.keymap").nnoremap

neogit.setup({})

nnoremap("<leader>gb", "<cmd>Git blame<cr>", {})

vim.api.nvim_create_autocmd({ "BufEnter" }, {
    callback = function()
        require("lazygit.utils").project_root_dir()
    end,
})
