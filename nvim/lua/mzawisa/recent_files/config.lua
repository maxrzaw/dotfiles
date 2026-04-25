local M = {}

---@class RecentFilesPickerConfig
---@field mappings? table<string, table<string, fun(prompt_bufnr: number)>> Telescope-style per-mode mappings applied to the custom picker.

---@class RecentFilesCompiledConfig
---@field ignore_patterns table[]

---@class RecentFilesConfig
---@field default_branch? string Preferred branch when resolving canonical worktree paths.
---@field repo_overrides? table<string, string> Override canonical branch by git common dir.
---@field max_entries? integer Maximum number of records persisted to disk.
---@field ignore_patterns? string[] Gitignore-style patterns excluded from tracking and display.
---@field skip_filetypes? table<string, boolean> Filetypes ignored by buffer tracking.
---@field picker? RecentFilesPickerConfig Telescope-facing picker options.

function M.defaults()
    return {
        default_branch = "main",
        repo_overrides = {},
        max_entries = 1000,
        ignore_patterns = {
            "COMMIT_EDITMSG",
            "MERGE_MSG",
            "TAG_EDITMSG",
            "git-rebase-todo",
            "**/.git/*",
            "node_modules/**",
            "bin/**",
            "obj/**",
            "dist/**",
            "coverage/**",
            "test_results/**",
            ".cache/**",
            "AppData/**",
            ".nuget/**",
            "*.tmp",
            "*.swp",
            "*.swo",
            "*~",
            ".DS_Store",
        },
        skip_filetypes = {
            ["alpha"] = true,
            ["lazy"] = true,
            ["mason"] = true,
            ["neo-tree"] = true,
            ["TelescopePrompt"] = true,
        },
        picker = {
            mappings = {},
        },
    }
end

---@param current RecentFilesConfig|nil
---@param opts RecentFilesConfig|nil
---@return RecentFilesConfig
function M.merge(current, opts)
    return vim.tbl_deep_extend("force", current or M.defaults(), opts or {})
end

---@param config RecentFilesConfig
---@param logic table
---@return RecentFilesCompiledConfig
function M.compile(config, logic)
    return {
        ignore_patterns = logic.compile_ignore_patterns(config.ignore_patterns),
    }
end

return M
