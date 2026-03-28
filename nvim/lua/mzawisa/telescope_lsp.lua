local api = vim.api
local lsp = vim.lsp

local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local themes = require("telescope.themes")
local utils = require("telescope.utils")

local M = {}

local function position_params(win, extra)
    if vim.fn.has("nvim-0.11") == 1 then
        return function(client)
            local params = lsp.util.make_position_params(win, client.offset_encoding)
            if extra then
                params = vim.tbl_extend("force", params, extra)
            end
            return params
        end
    end

    local params = lsp.util.make_position_params(win)
    if extra then
        params = vim.tbl_extend("force", params, extra)
    end
    return params
end

local function dedupe(items)
    local seen = {}
    local ret = {}

    for _, item in ipairs(items) do
        local key = table.concat({ item.filename or "", item.lnum or 0, item.col or 0 }, ":")
        if not seen[key] then
            seen[key] = true
            ret[#ret + 1] = item
        end
    end

    return ret
end

local function sort_items(items, opts)
    table.sort(items, function(a, b)
        local a_current = a.filename == opts.curr_filepath
        local b_current = b.filename == opts.curr_filepath
        if a_current ~= b_current then
            return a_current
        end

        if a.filename ~= b.filename then
            return a.filename < b.filename
        end

        if a.lnum ~= b.lnum then
            return a.lnum < b.lnum
        end

        return (a.col or 0) < (b.col or 0)
    end)

    return items
end

local function filter_file_ignore_patterns(items, opts)
    local file_ignore_patterns = vim.F.if_nil(opts.file_ignore_patterns, conf.file_ignore_patterns) or {}
    if vim.tbl_isempty(file_ignore_patterns) then
        return items
    end

    return vim.tbl_filter(function(item)
        for _, patt in ipairs(file_ignore_patterns) do
            if string.match(item.filename, patt) then
                return false
            end
        end
        return true
    end, items)
end

local function filter_current_line(items, opts)
    if opts.action ~= "textDocument/references" or opts.include_current_line then
        return items
    end

    local lnum = api.nvim_win_get_cursor(opts.winnr)[1]
    return vim.tbl_filter(function(item)
        return not (item.filename == opts.curr_filepath and item.lnum == lnum)
    end, items)
end

local function maybe_jump(items, first_encoding, opts)
    if #items ~= 1 or opts.jump_type == "never" then
        return false
    end

    local item = items[1]
    if opts.curr_filepath ~= item.filename or not opts.reuse_win then
        local cmd
        if opts.jump_type == "tab" then
            cmd = "tabedit"
        elseif opts.jump_type == "split" then
            cmd = "new"
        elseif opts.jump_type == "vsplit" then
            cmd = "vnew"
        elseif opts.jump_type == "tab drop" then
            cmd = "tab drop"
        end

        if cmd then
            vim.cmd(string.format("%s %s", cmd, item.filename))
        end
    end

    lsp.util.show_document(item.user_data, first_encoding, { reuse_win = opts.reuse_win })
    return true
end

local function list_or_jump(opts)
    opts.bufnr = vim.F.if_nil(opts.bufnr, api.nvim_get_current_buf())
    opts.winnr = vim.F.if_nil(opts.winnr, api.nvim_get_current_win())
    opts.reuse_win = vim.F.if_nil(opts.reuse_win, false)
    opts.curr_filepath = api.nvim_buf_get_name(opts.bufnr)

    lsp.buf_request_all(opts.bufnr, opts.action, opts.params, function(results_per_client)
        local items = {}
        local first_encoding

        for client_id, result_or_error in pairs(results_per_client) do
            local err = result_or_error.err
            local result = result_or_error.result

            if err then
                utils.notify(opts.notify_name, { msg = opts.action .. " : " .. err.message, level = "ERROR" })
            elseif result ~= nil then
                local locations = vim.islist(result) and result or { result }
                local client = lsp.get_client_by_id(client_id)
                local offset_encoding = client and client.offset_encoding or "utf-16"

                if not vim.tbl_isempty(locations) then
                    first_encoding = offset_encoding
                end

                vim.list_extend(items, lsp.util.locations_to_items(locations, offset_encoding))
            end
        end

        items = filter_current_line(items, opts)
        items = filter_file_ignore_patterns(items, opts)
        items = dedupe(items)
        items = sort_items(items, opts)

        if vim.tbl_isempty(items) then
            utils.notify(opts.notify_name, {
                msg = string.format("No %s found", opts.title),
                level = "INFO",
            })
            return
        end

        if maybe_jump(items, first_encoding, opts) then
            return
        end

        pickers
            .new(opts, {
                prompt_title = opts.title,
                finder = finders.new_table({
                    results = items,
                    entry_maker = opts.entry_maker or make_entry.gen_from_quickfix(opts),
                }),
                previewer = conf.qflist_previewer(opts),
                sorter = conf.generic_sorter(opts),
                push_cursor_on_edit = true,
                push_tagstack_on_edit = true,
            })
            :find()
    end)
end

local function get_opts(extra)
    return themes.get_ivy(vim.tbl_extend("force", {
        initial_mode = "normal",
        show_line = false,
    }, extra or {}))
end

function M.definitions()
    local opts = get_opts()
    opts.action = "textDocument/definition"
    opts.title = "LSP Definitions"
    opts.notify_name = "mzawisa.telescope_lsp.definitions"
    opts.params = position_params(opts.winnr)
    list_or_jump(opts)
end

function M.type_definitions()
    local opts = get_opts()
    opts.action = "textDocument/typeDefinition"
    opts.title = "LSP Type Definitions"
    opts.notify_name = "mzawisa.telescope_lsp.type_definitions"
    opts.params = position_params(opts.winnr)
    list_or_jump(opts)
end

function M.implementations()
    local opts = get_opts()
    opts.action = "textDocument/implementation"
    opts.title = "LSP Implementations"
    opts.notify_name = "mzawisa.telescope_lsp.implementations"
    opts.params = position_params(opts.winnr)
    list_or_jump(opts)
end

function M.references()
    local opts = get_opts({ include_declaration = false })
    opts.action = "textDocument/references"
    opts.title = "LSP References"
    opts.notify_name = "mzawisa.telescope_lsp.references"
    opts.include_current_line = false
    opts.params = position_params(opts.winnr, {
        context = { includeDeclaration = vim.F.if_nil(opts.include_declaration, true) },
    })
    list_or_jump(opts)
end

return M
