--- Set a bunch of options
require("mzawisa.set")

-- Bootstrap Lazy
vim.g.is_work = os.getenv("NEOVIM_WORK")
vim.g.is_pi = os.getenv("NEOVIM_PI")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Set Up Plugins
require("lazy").setup({
    ---@diagnostic disable-next-line: assign-type-mismatch
    dev = {
        path = "~/dev",
        patterns = { "maxzawisa", "mzawisa", "maxrzaw", "https://gitlab.com/schrieveslaach" },
        fallback = true,
    },
    ui = {
        border = "rounded",
        title = " Lazy ",
    },
    install = {
        missing = true,
        colorscheme = { "catppuccin", "default" },
    },
    spec = {
        { "lazy.nvim" },
        { import = "plugins" },
        {
            -- Special LSP config for neovim development
            "folke/lazydev.nvim",
            ft = "lua",
            opts = {
                library = { "conform.nvim", "harpoon", "nvim-dap", "nvim-dap-ui" },
            },
            cond = not vim.g.vscode,
        },
        {
            "norcalli/nvim-colorizer.lua",
        },
        {
            "catppuccin/nvim",
            lazy = false, -- make sure we load this during startup if it is your main colorscheme
            priority = 1000, -- make sure to load this before all the other start plugins
            config = function()
                require("catppuccin").setup({
                    flavour = "mocha",
                    transparent_background = true,
                    term_colors = true,
                    float = {
                        transparent = true,
                        solid = false,
                    },
                    auto_integrations = true,
                    integrations = {
                        alpha = true,
                        cmp = true,
                        copilot_vim = true,
                        dap = true,
                        dap_ui = true,
                        fidget = true,
                        gitsigns = true,
                        harpoon = true,
                        lsp_trouble = true,
                        mason = true,
                        neotree = true,
                        neotest = true,
                        telescope = true,
                        treesitter = true,
                    },
                    custom_highlights = function(mocha)
                        return {
                            LineNr = { fg = mocha.overlay1 },
                            NeoTreeDotfile = { fg = mocha.subtext0 },
                            NeoTreeFileStats = { fg = mocha.overlay2 },
                            NeoTreeMessage = { fg = mocha.overlay2 },
                        }
                    end,
                })
                vim.cmd.colorscheme("catppuccin")
            end,
            cond = not vim.g.vscode,
        },
        {
            "nvimtools/none-ls.nvim",
            config = function()
                local null_ls = require("null-ls")
                null_ls.setup({
                    sources = {
                        null_ls.builtins.code_actions.refactoring,
                        null_ls.builtins.diagnostics.todo_comments,
                        null_ls.builtins.hover.printenv,
                        null_ls.builtins.hover.dictionary,
                    },
                })
            end,
            dependencies = {
                "nvim-lua/plenary.nvim",
            },
            cond = not vim.g.vscode,
        },
        "tpope/vim-surround",
        {
            "https://gitlab.com/schrieveslaach/sonarlint.nvim",
            name = "sonarlint.nvim",
            branch = "main",
            dev = false,
            cond = vim.g.is_work and not vim.g.vscode,
            dependencies = {
                "mfussenegger/nvim-jdtls",
                cond = vim.g.is_work and not vim.g.vscode,
            },
        },

        -- Useful status updates for LSP
        {
            "j-hui/fidget.nvim",
            tag = "legacy",
            opts = {
                window = {
                    border = "rounded",
                    blend = 0,
                },
            },
            cond = not vim.g.vscode,
        },
        {
            "mbbill/undotree", -- ability to browse file history tree
            name = "Undo Tree",
            config = function()
                vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { silent = true, noremap = true })
            end,
            cond = not vim.g.vscode,
        },
        {
            dir = "~/dev/azdo.nvim",
            config = function()
                require("azdo").setup({})
            end,
            cond = false and not vim.g.is_pi and vim.g.windows ~= 1,
        },
        {
            "2kabhishek/nerdy.nvim",
            dependencies = {
                "nvim-telescope/telescope.nvim",
                "stevearc/dressing.nvim",
            },
            cmd = "Nerdy",
        },
        {
            "m4xshen/hardtime.nvim",
            dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
            opts = {
                disable_mouse = false,
                restriction_mode = "hint",
                max_count = 10,
                restricted_keys = {
                    ["j"] = {},
                    ["k"] = {},
                },
            },
        },
        { "tjdevries/present.nvim" },
    },
})

--- The rest of my user configuration
require("mzawisa.autocmds")
require("mzawisa.remaps")
