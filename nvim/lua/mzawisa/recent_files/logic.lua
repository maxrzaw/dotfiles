local M = {}

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
