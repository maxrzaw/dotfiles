-- Start of Mason
local mason = require("mason")
local mason_ensure_installed = {
    "bash-language-server",
    "css-lsp",
    "eslint-lsp",
    "html-lsp",
    "json-lsp",
    "lua-language-server",
    "marksman",
    "prettier",
    "stylua",
    "typescript-language-server",
    -- "angular-language-server",
    -- "cmake-language-server",
    -- "docker-compose-language-service",
    -- "dockerfile-language-server",
    -- "omnisharp",
    -- "rust-analyzer",
    -- "rustfmt",
    -- "sonarlint-language-server",
}

mason.setup({
    max_concurrent_installers = 10,
    ui = {
        border = "rounded",
    },
})

vim.api.nvim_create_user_command("MasonInstallAll", function()
    vim.cmd("MasonInstall " .. table.concat(mason_ensure_installed, " "))
end, {})

require("mason-lspconfig").setup()

-- End of Mason
