return {
    {
        "nvim-treesitter/nvim-treesitter",
        name = "nvim-treesitter",
        branch = "main",
        cond = not vim.g.vscode,
        dependencies = {
            { "windwp/nvim-ts-autotag" },
        },
        build = ":TSUpdate",
        config = function()
            local treesitter = require("nvim-treesitter")
            local parsers = {
                "vimdoc",
                "bash",
                "git_config",
                "git_rebase",
                "gitattributes",
                "gitcommit",
                "gitignore",
                "javascript",
                "json",
                "typescript",
                "lua",
                "c_sharp",
                "angular",
                "html",
                "markdown",
                "sql",
            }

            -- Configure zig as compiler on Windows
            if vim.g.windows == 1 then
                require("nvim-treesitter.install").compilers = { "zig" }
            end

            if treesitter.install then
                treesitter.setup()
                treesitter.install(parsers)
                require("nvim-ts-autotag").setup()

                local treesitter_group = vim.api.nvim_create_augroup("mzawisa-treesitter", { clear = true })
                local installing = {}

                local function start_treesitter(bufnr)
                    if not pcall(vim.treesitter.start, bufnr) then
                        return false
                    end

                    vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    return true
                end

                vim.api.nvim_create_autocmd("FileType", {
                    group = treesitter_group,
                    pattern = "*",
                    callback = function(args)
                        local bufnr = args.buf
                        local filetype = vim.bo[bufnr].filetype
                        local lang = vim.treesitter.language.get_lang(filetype) or filetype

                        if vim.bo[bufnr].buftype ~= "" or filetype == "php" then
                            return
                        end

                        if start_treesitter(bufnr) then
                            return
                        end

                        if not vim.tbl_contains(treesitter.get_available(), lang) or installing[lang] then
                            return
                        end

                        installing[lang] = true
                        treesitter.install(lang):await(function(err)
                            installing[lang] = nil

                            if err or not vim.api.nvim_buf_is_valid(bufnr) then
                                return
                            end

                            vim.schedule(function()
                                if vim.api.nvim_buf_is_valid(bufnr) then
                                    start_treesitter(bufnr)
                                end
                            end)
                        end)
                    end,
                })
            else
                require("nvim-treesitter.configs").setup({
                    ensure_installed = parsers,
                    sync_install = false,
                    auto_install = true,
                    ignore_install = {},
                    highlight = {
                        enable = true,
                        disable = { "php" },
                        additional_vim_regex_highlighting = false,
                    },
                    indent = {
                        enable = true,
                    },
                    autotag = {
                        enable = true,
                    },
                })
            end

            vim.treesitter.language.register("cpp", "arduino")
            vim.treesitter.language.register("terraform", "terraform-vars")
        end,
    },
}
