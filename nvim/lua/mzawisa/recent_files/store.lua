local M = {}

---@class RecentFilesStoreDeps
---@field state RecentFilesState
---@field logic table
---@field normalize_path fun(path: string|nil): string|nil
---@field path_exists fun(path: string|nil): boolean
---@field store_dir string
---@field store_path string

---@param deps RecentFilesStoreDeps
function M.new(deps)
    local state = deps.state
    local logic = deps.logic
    local normalize_path = deps.normalize_path
    local path_exists = deps.path_exists
    local store_dir = deps.store_dir
    local store_path = deps.store_path

    local function ensure_store_dir()
        vim.fn.mkdir(store_dir, "p")
    end

    local function read_file(path)
        if not path_exists(path) then
            return nil
        end

        local lines = vim.fn.readfile(path)
        return table.concat(lines, "\n")
    end

    local function write_file(path, contents)
        vim.fn.writefile(vim.split(contents, "\n", { plain = true }), path)
    end

    local function read_store()
        ensure_store_dir()

        if not path_exists(store_path) then
            write_file(store_path, "[]")
        end

        return read_file(store_path)
    end

    local function write_store(records)
        ensure_store_dir()
        write_file(store_path, vim.json.encode(records))
    end

    local function decode_records(raw)
        local ok, decoded = pcall(vim.json.decode, raw)
        if ok and type(decoded) == "table" then
            return decoded
        end

        return {}
    end

    local function normalize_record(record)
        if type(record) ~= "table" or type(record.file) ~= "string" then
            return nil
        end

        local file = normalize_path(record.file)
        if not file then
            return nil
        end

        return {
            file = file,
            git_root = normalize_path(record.git_root),
            git_common_dir = normalize_path(record.git_common_dir),
            relative_path = record.relative_path,
            last_accessed = record.last_accessed,
        }
    end

    local function load_record_list(raw)
        local records = {}

        for _, record in ipairs(decode_records(raw)) do
            local normalized = normalize_record(record)
            if normalized then
                table.insert(records, normalized)
            end
        end

        return records
    end

    local function load_records()
        if state.loaded then
            return
        end

        for _, record in ipairs(load_record_list(read_store())) do
            state.records[record.file] = record
        end

        state.loaded = true
    end

    local function sorted_records()
        local records = {}
        for file, record in pairs(state.records) do
            if not state.stale[file] then
                table.insert(records, record)
            end
        end

        return logic.sort_records(records)
    end

    local function trim_records(records)
        return logic.trim_records(records, state.config.max_entries)
    end

    local function save_records()
        if not state.loaded then
            return
        end

        local disk_records = load_record_list(read_store())
        local merged = logic.merge_record_maps(logic.index_records(disk_records), state.records)
        merged = logic.apply_stale_records(merged, state.stale)
        local records = trim_records(logic.sort_records(logic.record_map_values(merged)))

        state.records = logic.index_records(records)
        write_store(records)
        state.stale = {}
    end

    local function mark_stale(file)
        if file and state.records[file] then
            state.stale[file] = os.time()
        end
    end

    return {
        load_records = load_records,
        sorted_records = sorted_records,
        save_records = save_records,
        mark_stale = mark_stale,
    }
end

return M
