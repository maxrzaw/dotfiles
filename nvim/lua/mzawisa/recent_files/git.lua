local M = {}

---@class RecentFilesGitDeps
---@field state RecentFilesState
---@field logic table
---@field normalize_path fun(path: string|nil): string|nil
---@field path_exists fun(path: string|nil): boolean
---@field mark_stale fun(file: string)

---@param deps RecentFilesGitDeps
function M.new(deps)
    local state = deps.state
    local logic = deps.logic
    local normalize_path = deps.normalize_path
    local path_exists = deps.path_exists
    local mark_stale = deps.mark_stale

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
            if logic.should_translate_to_context(record, context) then
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

    return {
        get_git_info = get_git_info,
        current_context = current_context,
        resolve_record_target = resolve_record_target,
    }
end

return M
