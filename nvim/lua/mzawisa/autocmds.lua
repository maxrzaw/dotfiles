local tbl_contains = require("mzawisa.utils").tbl_contains
local function augroup(name, opts)
    return vim.api.nvim_create_augroup("mzawisa_" .. name, opts or { clear = true })
end

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = augroup("resize_splits"),
    callback = function()
        local current_tab = vim.fn.tabpagenr()
        vim.cmd("tabdo wincmd =")
        vim.cmd("tabnext " .. current_tab)
    end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup("last_loc"),
    callback = function(event)
        local exclude = { "gitcommit" }
        local buf = event.buf
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].mzawisa_last_loc then
            return
        end
        vim.b[buf].mzawisa_last_loc = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("close_with_q"),
    pattern = {
        "PlenaryTestPopup",
        "help",
        "lspinfo",
        "man",
        "notify",
        "qf",
        "query",
        "spectre_panel",
        "startuptime",
        "tsplayground",
        "neotest-output",
        "checkhealth",
        "neotest-summary",
        "neotest-output-panel",
        "fugitiveblame",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

local number_group = augroup("line_numbers", { clear = false })
local number_exclude_filetypes = { "alpha" }

-- Turn off line numbers when I leave a buffer
vim.api.nvim_create_autocmd({ "WinLeave" }, {
    group = number_group,
    callback = function(ev)
        -- Set numbers off for the current buffer
        if tbl_contains(number_exclude_filetypes, vim.bo[ev.buf].filetype) then
            return
        end
        vim.opt_local.relativenumber = false
        vim.opt_local.number = true
    end,
})

-- Hide line numbers in these filetypes
vim.api.nvim_create_autocmd({ "WinEnter" }, {
    group = number_group,
    callback = function(ev)
        -- Set numbers off for the current buffer
        if tbl_contains(number_exclude_filetypes, vim.bo[ev.buf].filetype) then
            return
        end
        vim.opt_local.relativenumber = true
    end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("wrap_spell"),
    pattern = { "gitcommit", "markdown" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

-- Add Auto Command to close neotree when I switch to another buffer
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(ev)
        local filetype = vim.bo[ev.buf].filetype
        local win = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win())

        -- Skip floating windows and neotree itself
        if filetype == "neo-tree" or win.relative == "editor" then
            return
        end

        if not require("mzawisa.custom.neotree").pinned() then
            require("neo-tree.command").execute({ action = "close" })
        end
    end,
})
