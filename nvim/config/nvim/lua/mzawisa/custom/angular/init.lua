local path = require("plenary.path")

local M = {}
M.enabled = false

local function load_file_into_buffer(file)
    local uri = vim.uri_from_fname(file)
    local bufnrs = vim.api.nvim_list_bufs()
    for _, v in pairs(bufnrs) do
        local buf_name = vim.api.nvim_buf_get_name(v)
        print(buf_name)
    end
    local new_buff = vim.uri_to_bufnr(uri)
    vim.api.nvim_win_set_buf(0, new_buff)
    vim.fn.execute("edit")
end

function M.start_angularls()
    vim.cmd("LspStart angularls")
end

local function get_destination_without_extension()
    local current_buffer = vim.api.nvim_buf_get_name(0)
    local buf_path = path:new(current_buffer)
    local relative_path = buf_path:make_relative()
    local filename = string.match(relative_path, "([^/]+)$")

    local filename_without_ext = nil
    if string.match(filename, ".html") then
        filename_without_ext = string.match(filename, "(.-)%.html")
    elseif string.match(filename, ".spec.ts") then
        filename_without_ext = string.match(filename, "(.-)%.spec.ts")
    elseif string.match(filename, ".ts") then
        filename_without_ext = string.match(filename, "(.-)%.ts")
    elseif string.match(filename, ".scss") then
        filename_without_ext = string.match(filename, "(.-)%.scss")
    end
    return buf_path:parent() .. "/" .. filename_without_ext
end

local function go_to_file_with_ext(ext)
    local full_destination = get_destination_without_extension() .. ext

    local exists = vim.fn.filereadable(full_destination)
    -- don't open a buffer if the file doesn't exist since you may end up creating a file without knowing it
    if exists == 0 then
        vim.notify("File doesn't exist: " .. full_destination, vim.log.levels.WARN)
        return
    end

    load_file_into_buffer(full_destination)
end

function M.go_to_template_file()
    go_to_file_with_ext(".html")
end
function M.go_to_spec_file()
    go_to_file_with_ext(".spec.ts")
end
function M.go_to_component_file()
    go_to_file_with_ext(".ts")
end
function M.go_to_style_file()
    go_to_file_with_ext(".scss")
end

function M.set_enabled(value)
    M.enabled = value
end

function M.set_quickswitch_keybindings()
    vim.keymap.set("n", "<leader>sp", M.go_to_spec_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Go to Angular Spec",
    })
    vim.keymap.set("n", "<leader>ss", M.go_to_style_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Go to Angular Style",
    })
    vim.keymap.set("n", "<leader>tt", M.go_to_template_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Go to Angular Template",
    })
    vim.keymap.set("n", "<leader>ts", M.go_to_component_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Go to Angular Component",
    })
end

return M
