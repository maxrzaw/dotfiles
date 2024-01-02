-- Function to find the root directory of the project
local function find_project_root()
    ---@type string
    local current_dir = vim.uv.cwd()
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
    return vim.uv.cwd()
end

---@param current_filename string current file
---@param filename string filename to make relative to current file
---@param root string Don't go further than this directory
---@return string
local function make_relative(current_filename, filename, root)
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

return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dev = true,
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local Path = require("plenary.path")
        local Harpoon = require("harpoon")
        local default_config = Harpoon.config.default

        Harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = function()
                    -- return vim.uv.cwd()
                    return find_project_root()
                end,
            },
            relative = {
                select = function(list_item, list, options)
                    default_config.select(list_item, list, options)
                end,
                get_root_dir = function()
                    return find_project_root()
                end,
                equals = function(a, b)
                    return a.value == b.value
                end,
                create_list_item = function(config, name)
                    local path = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                    name = name or path
                    if string.sub(name, 1, 1) ~= "/" then
                        local dir = Path:new(path):parent().filename
                        path = dir .. "/" .. name
                    end
                    local bufnr = vim.fn.bufnr(path, false)

                    local pos = { 1, 0 }
                    if bufnr ~= -1 then
                        pos = vim.api.nvim_win_get_cursor(0)
                    end

                    return {
                        value = path,
                        context = {
                            row = pos[1],
                            col = pos[2],
                        },
                    }
                end,
                display = function(ui_context, list_item)
                    if ui_context ~= nil then
                        return make_relative(ui_context, list_item.value, find_project_root())
                    end
                    return default_config.display(ui_context, list_item)
                end,
                BufLeave = function(arg, list)
                    local bufnr = arg.buf
                    local bufname = vim.api.nvim_buf_get_name(bufnr)
                    local item = nil
                    for _, it in ipairs(list.items) do
                        local value = it.value
                        if value == bufname then
                            item = it
                        end
                    end

                    if item then
                        local pos = vim.api.nvim_win_get_cursor(0)

                        item.context.row = pos[1]
                        item.context.col = pos[2]
                    end
                end,
            },
        })

        -- Harpoon
        vim.keymap.set("n", "<leader>m", function()
            Harpoon:list():append()
            -- Harpoon:list("relative"):append()
        end)
        vim.keymap.set("n", "<leader>h", function()
            local path = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
            -- Harpoon.ui:toggle_quick_menu(Harpoon:list("relative"), {
            Harpoon.ui:toggle_quick_menu(Harpoon:list(), {
                border = "rounded",
                title_pos = "center",
                title = " >-> Harpoon <-< ",
                ui_max_width = 80,
                context = path,
            })
        end)
    end,
    cond = not vim.g.vscode,
}
