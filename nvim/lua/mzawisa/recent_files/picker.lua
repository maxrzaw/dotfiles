local M = {}

---@class RecentFilesPickerDeps
---@field logic table
---@field load_records fun()
---@field sorted_records fun(): RecentFileRecord[]
---@field current_context fun(): RecentFilesContext|nil
---@field resolve_record_target fun(record: RecentFileRecord, context: RecentFilesContext|nil): string|nil
---@field should_ignore_record fun(file: string, record?: RecentFileRecord): boolean
---@field normalize_path fun(path: string|nil): string|nil
---@field get_config fun(): RecentFilesConfig

---@param deps RecentFilesPickerDeps
function M.new(deps)
    local logic = deps.logic
    local load_records = deps.load_records
    local sorted_records = deps.sorted_records
    local current_context = deps.current_context
    local resolve_record_target = deps.resolve_record_target
    local should_ignore_record = deps.should_ignore_record
    local normalize_path = deps.normalize_path
    local get_config = deps.get_config

    local function worktree_label(record)
        if not record.git_root then
            return "non-git"
        end

        local basename = vim.fs.basename(record.git_root)
        return basename ~= "" and basename or record.git_root
    end

    local function display_parts(record, resolved, context)
        if record.git_common_dir and record.relative_path then
            if context and context.git_common_dir == record.git_common_dir then
                return "", record.relative_path
            end

            return string.format("[%s] ", worktree_label(record)), record.relative_path
        end

        return "", vim.fn.fnamemodify(resolved, ":~")
    end

    local function make_display(item)
        local strings = require("plenary.strings")
        local state = require("telescope.state")
        local prefix = item.prefix or ""
        local path = item.path_display or ""
        local status = state.get_status(vim.api.nvim_get_current_buf())
        local width = vim.api.nvim_win_get_width(status.layout.results.winid) - #status.picker.selection_caret - 2
        local truncated = strings.truncate(path, width - vim.fn.strdisplaywidth(prefix), nil, -1)

        return prefix .. truncated
    end

    local function picker_items()
        load_records()

        local context = current_context()
        local current_file = normalize_path(vim.api.nvim_buf_get_name(0))
        local seen = {}
        local items = {}

        for _, record in ipairs(sorted_records()) do
            if not should_ignore_record(record.file, record) then
                local target = resolve_record_target(record, context)
                if target and target ~= current_file then
                    local key = logic.display_dedupe_key(record, context)

                    if not seen[key] then
                        seen[key] = true
                        local prefix, path_display = display_parts(record, target, context)
                        table.insert(items, {
                            record = record,
                            filename = target,
                            prefix = prefix,
                            path_display = path_display,
                            ordinal = table.concat({
                                record.relative_path or record.file,
                                target,
                                worktree_label(record),
                            }, " "),
                        })
                    end
                end
            end
        end

        return items
    end

    local function configured_mappings(opts)
        local config = get_config and get_config() or {}
        local picker_config = config.picker or {}

        return vim.tbl_deep_extend("force", picker_config.mappings or {}, opts.mappings or {})
    end

    local function apply_mappings(map, prompt_bufnr, mappings)
        for _, mode in ipairs({ "i", "n" }) do
            for lhs, handler in pairs(mappings[mode] or {}) do
                map(mode, lhs, function()
                    handler(prompt_bufnr)
                end)
            end
        end
    end

    local function open_picker(opts)
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        opts = opts or {}
        local items = picker_items()

        pickers
            .new(opts, {
                prompt_title = "Recent Files",
                finder = finders.new_table({
                    results = items,
                    entry_maker = function(item)
                        return {
                            value = item.record,
                            ordinal = item.ordinal,
                            display = function()
                                return make_display(item)
                            end,
                            filename = item.filename,
                        }
                    end,
                }),
                previewer = conf.file_previewer(opts),
                sorter = conf.generic_sorter(opts),
                attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection and selection.filename then
                            vim.cmd.edit(vim.fn.fnameescape(selection.filename))
                        end
                    end)

                    apply_mappings(map, prompt_bufnr, configured_mappings(opts))
                    return true
                end,
            })
            :find()
    end

    return {
        open_picker = open_picker,
    }
end

return M
