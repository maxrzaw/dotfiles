return {
    {
        "akinsho/nvim-toggleterm.lua",
        config = function()
            require("toggleterm").setup({
                open_mapping = [[<c-t>]],
                direction = "float",
                float_opts = {
                    border = "rounded",
                },
            })
            local lazygit = require("toggleterm.terminal").Terminal:new({
                cmd = "lazygit",
                hidden = true,
            })
            local function _lazygit_toggle()
                lazygit:toggle()
            end
            vim.keymap.set("n", "<leader>lg", _lazygit_toggle, { silent = true, desc = "LazyGit" })
        end,
        cond = not vim.g.vscode,
    },
}
