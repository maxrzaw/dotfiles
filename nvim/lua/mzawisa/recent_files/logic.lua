local M = {}

---@class RecentFileRecord
---@field file string
---@field git_root? string
---@field git_common_dir? string
---@field relative_path? string
---@field last_accessed? integer

---@class RecentFilesContext
---@field git_root string
---@field git_common_dir string

---@class RecentFilesWorktree
---@field path string
---@field branch? string
---@field git_common_dir? string

---@class RecentFilesIgnorePattern
---@field negated boolean
---@field basename_only boolean
---@field regex string

local function glob_to_lua_pattern(glob)
    local pattern = { "^" }
    local i = 1

    while i <= #glob do
        local char = glob:sub(i, i)
        local next_two = glob:sub(i, i + 1)

        if next_two == "**" then
            table.insert(pattern, ".*")
            i = i + 2
        elseif char == "*" then
            table.insert(pattern, "[^/]*")
            i = i + 1
        elseif char == "?" then
            table.insert(pattern, "[^/]")
            i = i + 1
        elseif char:match("[%]%(%)%%%.%+%-%^%$]") then
            table.insert(pattern, "%" .. char)
            i = i + 1
        else
            table.insert(pattern, char)
            i = i + 1
        end
    end

    table.insert(pattern, "$")
    return table.concat(pattern)
end

local function normalize_ignore_pattern(pattern)
    if type(pattern) ~= "string" then
        return nil
    end

    local trimmed = vim.trim(pattern)
    if trimmed == "" or trimmed:sub(1, 1) == "#" then
        return nil
    end

    local negated = trimmed:sub(1, 1) == "!"
    if negated then
        trimmed = vim.trim(trimmed:sub(2))
        if trimmed == "" then
            return nil
        end
    end

    local anchored = trimmed:sub(1, 1) == "/"
    if anchored then
        trimmed = trimmed:sub(2)
    end

    local basename_only = not anchored and not trimmed:find("/", 1, true)

    return {
        negated = negated,
        basename_only = basename_only,
        regex = glob_to_lua_pattern(trimmed),
    }
end

function M.compile_ignore_patterns(patterns)
    local compiled = {}

    for _, pattern in ipairs(patterns or {}) do
        local normalized = normalize_ignore_pattern(pattern)
        if normalized then
            table.insert(compiled, normalized)
        end
    end

    return compiled
end

function M.matches_ignore_patterns(path, compiled_patterns, opts)
    if type(path) ~= "string" or path == "" then
        return false
    end

    opts = opts or {}
    local basename = opts.basename
    local relative_path = opts.relative_path
    local ignored = false

    for _, pattern in ipairs(compiled_patterns or {}) do
        local candidate = pattern.basename_only and basename or relative_path or path
        local matches = candidate and candidate:match(pattern.regex)

        if not matches and candidate and not pattern.basename_only then
            matches = ("/" .. candidate):match(pattern.regex)
        end

        if matches then
            ignored = not pattern.negated
        end
    end

    return ignored
end

function M.relative_to_root(path, root, normalize)
    if not path or not root then
        return nil
    end

    if normalize then
        root = normalize(root)
        path = normalize(path)
    end

    if not root or not path then
        return nil
    end

    if path == root then
        return "."
    end

    local prefix = root .. "/"
    if path:sub(1, #prefix) == prefix then
        return path:sub(#prefix + 1)
    end

    return nil
end

function M.branch_from_ref(ref)
    if not ref then
        return nil
    end

    return ref:match("^refs/heads/(.+)$") or ref
end

function M.get_target_branch(config, common_dir)
    config = config or {}
    local repo_overrides = config.repo_overrides or {}
    return repo_overrides[common_dir] or config.default_branch or "main"
end

function M.dedupe_key(record)
    if record.git_common_dir and record.relative_path then
        return string.format("git:%s:%s", record.git_common_dir, record.relative_path)
    end

    return "file:" .. record.file
end

function M.record_identity_key(record)
    return "file:" .. record.file
end

function M.should_translate_to_context(record, context)
    return record.git_common_dir ~= nil
        and record.relative_path ~= nil
        and context ~= nil
        and context.git_common_dir == record.git_common_dir
end

function M.display_dedupe_key(record, context)
    if M.should_translate_to_context(record, context) then
        return M.dedupe_key(record)
    end

    return M.record_identity_key(record)
end

function M.sort_records(records)
    table.sort(records, function(a, b)
        return (a.last_accessed or 0) > (b.last_accessed or 0)
    end)
    return records
end

function M.trim_records(records, max_entries)
    if not max_entries or #records <= max_entries then
        return records
    end

    local trimmed = {}
    for index, record in ipairs(records) do
        if index > max_entries then
            break
        end
        table.insert(trimmed, record)
    end

    return trimmed
end

function M.pick_representatives(records, include_record)
    local seen = {}
    local representatives = {}

    for _, record in ipairs(records) do
        if not include_record or include_record(record) then
            local key = M.dedupe_key(record)
            if not seen[key] then
                seen[key] = true
                table.insert(representatives, record)
            end
        end
    end

    return representatives
end

function M.index_records(records)
    local indexed = {}

    for _, record in ipairs(records or {}) do
        if type(record) == "table" and type(record.file) == "string" then
            indexed[record.file] = record
        end
    end

    return indexed
end

function M.merge_record_maps(disk_map, memory_map)
    local merged = {}

    for file, record in pairs(disk_map or {}) do
        merged[file] = record
    end

    for file, record in pairs(memory_map or {}) do
        local existing = merged[file]
        if not existing or (record.last_accessed or 0) >= (existing.last_accessed or 0) then
            merged[file] = record
        end
    end

    return merged
end

function M.apply_stale_records(record_map, stale_map)
    local filtered = {}

    for file, record in pairs(record_map or {}) do
        local stale_at = stale_map and stale_map[file] or nil
        if not stale_at or stale_at < (record.last_accessed or 0) then
            filtered[file] = record
        end
    end

    return filtered
end

function M.record_map_values(record_map)
    local records = {}

    for _, record in pairs(record_map or {}) do
        table.insert(records, record)
    end

    return records
end

return M
