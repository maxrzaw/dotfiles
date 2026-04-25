local M = {}

function M.normalize(path)
    if not path or path == "" then
        return nil
    end

    local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    if normalized:sub(-1) == "/" then
        normalized = normalized:sub(1, -2)
    end
    return normalized
end

function M.exists(path)
    return path and vim.uv.fs_stat(path) ~= nil
end

return M
