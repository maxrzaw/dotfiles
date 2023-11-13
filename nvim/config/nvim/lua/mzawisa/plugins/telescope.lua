local telescope = require("telescope")
local builtin = require("telescope.builtin")
local keymap = require("mzawisa.keymap")
local nnoremap = keymap.nnoremap

telescope.setup({
    defaults = {
        layout_config = { width = 0.95 },
        path_display = { "smart" },
    },
    pickers = {
        diagnostics = {
            theme = "ivy",
            path_display = "hidden",
        },
        lsp_definitions = {
            theme = "ivy",
        },
        lsp_type_definitions = {
            theme = "ivy",
        },
        lsp_references = {
            theme = "ivy",
            -- shorten_path = false,
        },
    },
})

telescope.load_extension("harpoon")
telescope.load_extension("luasnip")
telescope.load_extension("lazygit")
-- telescope.load_extension("ui-select")

nnoremap("<leader>ff", builtin.find_files, {})
nnoremap("<leader>fgf", builtin.git_files, {})
nnoremap("<leader>fr", builtin.oldfiles, {})
nnoremap("<leader>fg", builtin.live_grep, {})
nnoremap("<leader>fb", builtin.buffers, {})
nnoremap("<leader>fh", builtin.help_tags, {})
nnoremap("<leader>fgs", builtin.git_status, {})
nnoremap("<leader>fgb", builtin.git_branches, {})
nnoremap("<leader>fgc", builtin.git_commits, {})
nnoremap("<leader>fq", builtin.quickfix, {})
nnoremap("<leader>fj", builtin.jumplist, {})
nnoremap("<leader>fk", builtin.keymaps, {})
