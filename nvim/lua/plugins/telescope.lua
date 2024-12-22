local get_opts = require("mzawisa.keymap").get_opts
return {
    {
        "nvim-telescope/telescope.nvim",
        version = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "benfowler/telescope-luasnip.nvim",
            -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            { "nvim-telescope/telescope-ui-select.nvim" },
            { "folke/trouble.nvim" },
        },
        cond = not vim.g.vscode,
        config = function()
            local builtin = require("telescope.builtin")
            local actions = require("telescope.actions")
            local trouble = require("trouble.providers.telescope")
            local open_with_trouble = function(...)
                return require("trouble.sources.telescope").open(...)
            end

            local telescope = require("telescope")
            local harpoon_add_mark = function(cwd, filename)
                local Path = require("pathlib")
                local absolute_path = tostring(Path(cwd) / filename)
                local list = require("harpoon"):list()
                local harpoon_config = list.config
                local item = harpoon_config.create_list_item(harpoon_config, absolute_path)
                list:add(item)
            end
            local get_entry = function(prompt_bufnr)
                local action_state = require("telescope.actions.state")
                return action_state.get_selected_entry()
            end
            local harpoon_add_mark__entry1 = function(prompt_bufnr)
                local entry = get_entry(prompt_bufnr)
                if entry == nil then
                    return
                end
                harpoon_add_mark(nil, entry[1])
            end
            local harpoon_add_mark__cwd_entry1 = function(prompt_bufnr)
                local entry = get_entry(prompt_bufnr)
                if entry == nil then
                    return
                end
                harpoon_add_mark(entry.cwd, entry[1])
            end
            local harpoon_add_mark__filename = function(prompt_bufnr)
                local entry = get_entry(prompt_bufnr)
                if entry == nil then
                    return
                end
                harpoon_add_mark(nil, entry.filename)
            end
            local harpoon_add_mark__cwd_filename = function(prompt_bufnr)
                local entry = get_entry(prompt_bufnr)
                if entry == nil then
                    return
                end
                harpoon_add_mark(entry.cwd, entry.filename)
            end
            local create_picker_config = function(func)
                return {
                    mappings = {
                        i = {
                            ["<C-r>"] = func,
                        },
                        n = {
                            ["<C-r>"] = func,
                        },
                    },
                }
            end
            local cwd_plus_filename = create_picker_config(harpoon_add_mark__cwd_filename)
            local just_entry1 = create_picker_config(harpoon_add_mark__entry1)
            local just_filename = create_picker_config(harpoon_add_mark__filename)
            local cwd_plus_entry1 = create_picker_config(harpoon_add_mark__cwd_entry1)
            telescope.setup({
                defaults = {
                    layout_config = { width = 0.95 },
                    path_display = { "smart" },
                    file_ignore_patterns = { "node_modules/", ".git/", "bin/", "obj/" },
                    mappings = {
                        i = {
                            ["<C-t>"] = open_with_trouble,
                            ["<C-q>"] = function(prompt_bufnr)
                                actions.send_to_qflist(prompt_bufnr)
                                trouble.open("quickfix")
                            end,
                            ["<C-h>"] = "which_key",
                        },
                        n = {
                            ["<C-t>"] = open_with_trouble,
                            ["<C-q>"] = function(prompt_bufnr)
                                actions.send_to_qflist(prompt_bufnr)
                                trouble.open("quickfix")
                            end,
                            ["<C-h>"] = "which_key",
                        },
                    },
                },
                pickers = {
                    diagnostics = {
                        theme = "ivy",
                        initial_mode = "normal",
                        path_display = "hidden",
                    },
                    lsp_definitions = {
                        theme = "ivy",
                        initial_mode = "normal",
                    },
                    lsp_type_definitions = {
                        theme = "ivy",
                        initial_mode = "normal",
                    },
                    lsp_implementations = {
                        theme = "ivy",
                        initial_mode = "normal",
                    },
                    lsp_references = {
                        theme = "ivy",
                        initial_mode = "normal",
                        include_declaration = false,
                        -- shorten_path = false,
                    },
                    find_files = cwd_plus_entry1,
                    git_files = cwd_plus_entry1,
                    live_grep = cwd_plus_filename,
                    grep_string = cwd_plus_filename,
                    buffers = cwd_plus_filename,
                    help_tags = just_filename,
                    quickfix = just_filename,
                    jumplist = just_filename,
                    oldfiles = just_entry1,
                },
            })

            telescope.load_extension("luasnip")
            telescope.load_extension("ui-select")

            vim.keymap.set("n", "<leader>ff", function()
                builtin.find_files({ hidden = true, no_ignore = true, no_ignore_parent = true })
            end, get_opts("Telescope: [F]ind [F]iles"))
            vim.keymap.set("n", "<leader>fgf", builtin.git_files, get_opts("Telescope: [F]ind [G]it [F]iles"))
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, get_opts("Telescope: [F]ind Live [G]rep"))
            vim.keymap.set("n", "<leader>gs", builtin.grep_string, get_opts("Telescope: [G]rep [S]tring"))
            vim.keymap.set("n", "<leader>fb", builtin.buffers, get_opts("Telescope: [F]ind [B]uffers"))
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, get_opts("Telescope: [F]ind [H]elp Tags"))
            vim.keymap.set("n", "<leader>fq", builtin.quickfix, get_opts("Telescope: [F]ind [Q]uickfix List"))
            vim.keymap.set("n", "<leader>fj", builtin.jumplist, get_opts("Telescope: [F]ind [J]umplist"))
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, get_opts("Telescope: [F]ind [R]ecent Files"))
            vim.keymap.set("n", "<leader>fk", builtin.keymaps, get_opts("Telescope: [F]ind [K]eymaps"))
            vim.keymap.set("n", "<leader>fgs", builtin.git_status, get_opts("Telescope: [F]ind [G]it [S]tatus"))
            vim.keymap.set("n", "<leader>fgb", builtin.git_branches, get_opts("Telescope: [F]ind [G]it [B]ranches"))
            vim.keymap.set("n", "<leader>fgc", builtin.git_commits, get_opts("Telescope: [F]ind [G]it [C]ommits"))
        end,
    },
}
