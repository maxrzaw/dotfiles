local path = require("plenary.path")

local M = {}

-- Start the Angular Language Server if it is not already active
function M.start_angularls()
    local active_clients = vim.lsp.get_active_clients()
    for _, v in pairs(active_clients) do
        if v.name == "angularls" then
            print("found angularls")
            return
        end
    end
    local config = require("lspconfig.configs")["angularls"]
    if config then
        print("launching angularls")
        config.launch()
    end
end

local function load_file_into_buffer(file)
    local uri = vim.uri_from_fname(file)
    local new_buff = vim.uri_to_bufnr(uri)
    vim.api.nvim_win_set_buf(0, new_buff)
    vim.fn.execute("edit")
end

function M.toggle_between_spec_and_file()
    local current_buffer = vim.api.nvim_buf_get_name(0)
    local buf_path = path:new(current_buffer)
    local relative_path = buf_path:make_relative()
    local filename = string.match(relative_path, "([^/]+)$")

    local full_destination = nil
    if string.match(filename, ".spec.ts") then
        -- if the current file is a spec file, then jump to the file it is testing
        local file_name = string.match(filename, "(.-)%.spec")
        full_destination = buf_path:parent() .. "/" .. file_name .. ".ts"
    else
        -- if the current file is not a spec file, then jump to the spec file
        local filename_without_ext = string.match(filename, "(.-)%.ts")
        full_destination = buf_path:parent() .. "/" .. filename_without_ext .. ".spec.ts"
    end

    local exists = vim.fn.filereadable(full_destination)
    -- don't open a buffer if the file doesn't exist since you may end up creating a file without knowing it
    if exists == 0 then
        vim.notify("File doesn't exist: " .. full_destination, vim.log.levels.WARN)
        return
    end

    load_file_into_buffer(full_destination)
end

return M
