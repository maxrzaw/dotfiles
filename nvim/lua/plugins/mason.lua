return {
    "williamboman/mason.nvim",
    opts = {
        max_concurrent_installers = 10,
        ui = {
            border = "rounded",
        },
        ensure_installed = {
            "tree-sitter-cli",
            "eslint-lsp",
            "lua-language-server",
            "typescript-language-server",
            "angular-language-server",
            -- "angular-language-server@15.2.1",
            "markdownlint",
            "marksman",
            "commitlint",
            "prettierd",
            "tailwindcss-language-server",
            "bash-language-server",
            "css-lsp",
            "html-lsp",
            "json-lsp",
            "js-debug-adapter@1.76.1",
            "editorconfig-checker",
            "docker-compose-language-service",
            "dockerfile-language-server",
            "sonarlint-language-server",
        },
    },
    config = function(_, opts)
        require("mason").setup(opts)
        vim.api.nvim_create_user_command("MasonInstallAll", function()
            vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
        end, {})
    end,
    cond = not vim.g.vscode,
}
