require("nvim-cursorline").setup({
    cursorline = {
        enable = true,
        timeout = 5000,
        number = false,
    },
    cursorword = {
        enable = true,
        min_length = 3,
        hl = {
            underline = true,
            bold = true,
        },
    },
})
