local keymap = require("mzawisa.keymap");
local builtin = require('telescope.builtin')
require('telescope').setup({
    defaults = {
        layout_config = { width = 0.95 },
        path_display = { 'smart' },
    },
    pickers = {
        diagnostics = {
            theme = 'ivy',
            path_display = 'hidden',
        },
        lsp_definitions = {
            theme = 'ivy',
        },
        lsp_type_definitions = {
            theme = 'ivy',
        },
        lsp_references = {
            theme = 'ivy',
            -- shorten_path = false,
        },
    },
})

require("telescope").load_extension('harpoon')
require('telescope').load_extension('lazygit')
local nnoremap = keymap.nnoremap;

nnoremap('<leader>ff', builtin.find_files, {})
nnoremap('<leader>fg', builtin.live_grep, {})
nnoremap('<leader>fgf', builtin.git_files, {})
nnoremap('<leader>fb', builtin.buffers, {})
nnoremap('<leader>fh', builtin.help_tags, {})
nnoremap('<leader>fgs', builtin.git_status, {})
nnoremap('<leader>fgb', builtin.git_branches, {})
nnoremap('<leader>fgc', builtin.git_commits, {})
nnoremap('<leader>fq', builtin.quickfix, {})
nnoremap('<leader>fj', builtin.jumplist, {})
nnoremap('<leader>fk', builtin.keymaps, {})
