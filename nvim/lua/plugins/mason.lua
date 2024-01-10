return {
    "williamboman/mason.nvim",
    opts = {
        max_concurrent_installers = 10,
        ui = {
            border = "rounded",
        },
        ensure_installed = {
            "markdownlint",
            "prettierd",
            "tailwindcss-language-server",
            "bash-language-server",
            "css-lsp",
            "eslint-lsp",
            "html-lsp",
            "json-lsp",
            "lua-language-server",
            "marksman",
            "typescript-language-server",
            "angular-language-server@15.2.1",
            "js-debug-adapter@1.76.1",
            "editorconfig-checker",
            -- "cmake-language-server",
            "docker-compose-language-service",
            "dockerfile-language-server",
            -- "omnisharp",
            -- "rust-analyzer",
            -- "rustfmt",
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
