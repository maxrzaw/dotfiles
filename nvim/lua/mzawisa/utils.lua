local M = {}

--- Function to get the current git branch or nil if there is no branch
---@return string|nil
function M.get_git_branch()
    local git_branch = vim.fn.systemlist("git branch --show-current")
    if git_branch[1] == "fatal: not a git repository (or any of the parent directories): .git" then
        return nil
    end
    return git_branch[1]
end

--- Function to find the root directory of the project
---@return string
function M.find_project_root()
    ---@type string
    local current_dir = vim.loop.cwd()
    local marker_files = { ".git", "package.json", ".sln" }

    -- Check each parent directory for the existence of a marker file or directory
    while current_dir ~= "/" do
        for _, marker in ipairs(marker_files) do
            local marker_path = current_dir .. "/" .. marker
            if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
                return current_dir
            end
        end
        current_dir = vim.fn.resolve(current_dir .. "/..")
    end
    -- If no marker file or directory is found, return the original directory
    return vim.loop.cwd()
end

--- Function to make a filename relative to the current file
---@param current_filename string current file
---@param filename string filename to make relative to current file
---@param root string Don't go further than this directory
---@return string
function M.make_relative(current_filename, filename, root)
    local Path = require("plenary.path")
    local dir = Path:new(current_filename):parent().filename
    local path = Path:new(filename):make_relative(dir)

    local common_parent = ""
    local prefix = ""
    for _, parent in ipairs(Path:new(current_filename):parents()) do
        if parent == root or string.find(parent, root) == nil then
            return Path:new(path):normalize(dir)
        end
        if string.find(path, parent) ~= nil then
            common_parent = parent
            break
        end
        prefix = prefix .. "../"
    end
    path = path:gsub(common_parent .. "/", prefix)

    return path
end

--- Function to check if value is in a table
--- @param table table
--- @param value any
--- @return boolean
function M.tbl_contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

return M
