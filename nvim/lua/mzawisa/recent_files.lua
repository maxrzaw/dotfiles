local M = {}

local logic = require("mzawisa.recent_files.logic")

local state = {
    loaded = false,
    setup_done = false,
    dirty = false,
    records = {},
    stale = {},
    config = {
        default_branch = "main",
        repo_overrides = {},
        max_entries = 1000,
        ignore_patterns = {},
    },
    compiled_ignore_patterns = {},
}

local store_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "mzawisa")
local store_path = vim.fs.joinpath(store_dir, "recent_files.json")
local skip_filetypes = {
    ["alpha"] = true,
    ["lazy"] = true,
    ["mason"] = true,
    ["neo-tree"] = true,
    ["TelescopePrompt"] = true,
}

local function normalize_path(path)
    if not path or path == "" then
        return nil
    end

    local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    if normalized:sub(-1) == "/" then
        normalized = normalized:sub(1, -2)
    end
    return normalized
end

local function path_exists(path)
    return path and vim.uv.fs_stat(path) ~= nil
end

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

local function run_git(args, cwd)
    local result = vim.system(vim.list_extend({ "git", "-C", cwd }, args), { text = true }):wait()
    if result.code ~= 0 then
        return nil
    end

    return vim.trim(result.stdout or "")
end

local function get_git_info(path)
    local normalized = normalize_path(path)
    if not normalized then
        return nil
    end

    local stat = vim.uv.fs_stat(normalized)
    if not stat then
        return nil
    end

    local cwd = stat.type == "directory" and normalized or vim.fs.dirname(normalized)
    local output = run_git({ "rev-parse", "--path-format=absolute", "--show-toplevel", "--git-common-dir" }, cwd)
    if not output then
        return nil
    end

    local lines = vim.split(output, "\n", { trimempty = true })
    if #lines < 2 then
        return nil
    end

    local git_root = normalize_path(lines[1])
    local git_common_dir = normalize_path(lines[2])
    if not git_root or not git_common_dir then
        return nil
    end

    return {
        git_root = git_root,
        git_common_dir = git_common_dir,
    }
end

local function list_worktrees(common_dir, git_root)
    if not common_dir or not git_root then
        return {}
    end

    local output = run_git({ "worktree", "list", "--porcelain" }, git_root)
    if not output then
        return {}
    end

    local worktrees = {}
    local current = nil
    for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
        local worktree = line:match("^worktree%s+(.+)$")
        if worktree then
            if current and current.path and current.git_common_dir == common_dir then
                table.insert(worktrees, current)
            end

            local worktree_path = normalize_path(worktree)
            local info = get_git_info(worktree_path)
            current = {
                path = worktree_path,
                branch = nil,
                git_common_dir = info and info.git_common_dir or nil,
            }
        elseif current then
            local branch = line:match("^branch%s+(.+)$")
            if branch then
                current.branch = logic.branch_from_ref(branch)
            end
        end
    end

    if current and current.path and current.git_common_dir == common_dir then
        table.insert(worktrees, current)
    end

    return worktrees
end

local function get_target_branch(common_dir)
    return logic.get_target_branch(state.config, common_dir)
end

local function get_canonical_root(record)
    if not record.git_common_dir or not record.git_root then
        return nil
    end

    local target_branch = get_target_branch(record.git_common_dir)
    for _, worktree in ipairs(list_worktrees(record.git_common_dir, record.git_root)) do
        if worktree.branch == target_branch then
            return worktree.path
        end
    end

    return nil
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
    state.dirty = false
    state.stale = {}
end

local function mark_stale(file)
    if file and state.records[file] then
        state.stale[file] = os.time()
        state.dirty = true
    end
end

local function current_context()
    local bufname = normalize_path(vim.api.nvim_buf_get_name(0))
    return get_git_info(bufname or vim.uv.cwd())
end

local function candidate_path(root, relative_path)
    if not root or not relative_path then
        return nil
    end

    local path = normalize_path(vim.fs.joinpath(root, relative_path))
    if path_exists(path) then
        return path
    end

    return nil
end

local function resolve_record_target(record, context)
    if record.git_common_dir and record.relative_path then
        if context and context.git_common_dir == record.git_common_dir then
            local translated = candidate_path(context.git_root, record.relative_path)
            if translated then
                return translated
            end
        end

        if path_exists(record.file) then
            return record.file
        end

        local canonical_root = get_canonical_root(record)
        local canonical = candidate_path(canonical_root, record.relative_path)
        if canonical then
            return canonical
        end

        for _, worktree in ipairs(list_worktrees(record.git_common_dir, record.git_root)) do
            local sibling = candidate_path(worktree.path, record.relative_path)
            if sibling then
                return sibling
            end
        end

        mark_stale(record.file)
        return nil
    end

    if path_exists(record.file) then
        return record.file
    end

    mark_stale(record.file)
    return nil
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
    state.dirty = true
end

local function should_ignore_record(file, record)
    local normalized = normalize_path(file)
    if not normalized then
        return false
    end

    local basename = vim.fs.basename(normalized)
    local relative_path = record and record.relative_path or normalized
    return logic.matches_ignore_patterns(normalized, state.compiled_ignore_patterns, {
        basename = basename,
        relative_path = relative_path,
    })
end

local function record_current_buffer(event)
    local buf = event and event.buf or 0
    if vim.bo[buf].buftype ~= "" then
        return
    end

    if skip_filetypes[vim.bo[buf].filetype] then
        return
    end

    local file = vim.api.nvim_buf_get_name(buf)
    if should_ignore_record(file) then
        return
    end

    track_file(file)
end

local function worktree_label(record)
    if not record.git_root then
        return "non-git"
    end

    local basename = vim.fs.basename(record.git_root)
    return basename ~= "" and basename or record.git_root
end

local function make_display(record, resolved, context)
    if record.git_common_dir and record.relative_path then
        if context and context.git_common_dir == record.git_common_dir then
            return record.relative_path
        end

        return string.format("[%s] %s", worktree_label(record), record.relative_path)
    end

    return vim.fn.fnamemodify(resolved, ":~")
end

local function picker_items()
    load_records()

    local context = current_context()
    local current_file = normalize_path(vim.api.nvim_buf_get_name(0))
    local seen = {}
    local items = {}

    for _, record in ipairs(sorted_records()) do
        if not state.stale[record.file] and not should_ignore_record(record.file, record) then
            local target = resolve_record_target(record, context)
            if target and target ~= current_file then
                local key
                key = logic.dedupe_key(record)

                if not seen[key] then
                    seen[key] = true
                    table.insert(items, {
                        record = record,
                        filename = target,
                        display = make_display(record, target, context),
                        ordinal = (record.relative_path or record.file) .. " " .. worktree_label(record),
                    })
                end
            end
        end
    end

    return items
end

local function tag_selected(prompt_bufnr)
    local selection = require("telescope.actions.state").get_selected_entry()
    if not selection or not selection.filename then
        return
    end

    local ok, grapple = pcall(require, "grapple")
    if not ok then
        return
    end

    grapple.tag({ path = selection.filename })
end

function M.open_picker(opts)
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
                        display = item.display,
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

                map({ "i", "n" }, "<C-r>", function()
                    tag_selected(prompt_bufnr)
                end)

                return true
            end,
        })
        :find()
end

function M.setup(opts)
    state.config = vim.tbl_deep_extend("force", state.config, opts or {})
    state.compiled_ignore_patterns = logic.compile_ignore_patterns(state.config.ignore_patterns)

    if state.setup_done then
        return
    end

    load_records()

    local group = vim.api.nvim_create_augroup("mzawisa_recent_files", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = group,
        callback = record_current_buffer,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            save_records()
        end,
    })

    state.setup_done = true
end

return M
