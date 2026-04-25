local M = {}

---@class RecentFilesTrackerDeps
---@field state RecentFilesState
---@field logic table
---@field normalize_path fun(path: string|nil): string|nil
---@field path_exists fun(path: string|nil): boolean
---@field get_git_info fun(path: string): RecentFilesContext|nil
---@field load_records fun()

---@param deps RecentFilesTrackerDeps
function M.new(deps)
    local state = deps.state
    local logic = deps.logic
    local normalize_path = deps.normalize_path
    local path_exists = deps.path_exists
    local get_git_info = deps.get_git_info
    local load_records = deps.load_records

    local function should_ignore_record(file, record)
        local normalized = normalize_path(file)
        if not normalized then
            return false
        end

        local basename = vim.fs.basename(normalized)
        local relative_path = record and record.relative_path or normalized
        return logic.matches_ignore_patterns(normalized, state.compiled.ignore_patterns, {
            basename = basename,
            relative_path = relative_path,
        })
    end

    local function track_file(file)
        load_records()

        local normalized = normalize_path(file)
        if not normalized or not path_exists(normalized) then
            return
        end

        local info = get_git_info(normalized)
        local record = state.records[normalized] or { file = normalized }
        record.file = normalized
        record.git_root = info and info.git_root or nil
        record.git_common_dir = info and info.git_common_dir or nil
        record.relative_path = info and logic.relative_to_root(normalized, info.git_root, normalize_path) or nil
        record.last_accessed = os.time()
        state.records[normalized] = record
        state.stale[normalized] = nil
    end

    local function record_current_buffer(event)
        local buf = event and event.buf or 0
        if vim.bo[buf].buftype ~= "" then
            return
        end

        local skip_filetypes = state.config.skip_filetypes or {}
        if skip_filetypes[vim.bo[buf].filetype] then
            return
        end

        local file = vim.api.nvim_buf_get_name(buf)
        if should_ignore_record(file) then
            return
        end

        track_file(file)
    end

    return {
        should_ignore_record = should_ignore_record,
        track_file = track_file,
        record_current_buffer = record_current_buffer,
    }
end

return M
