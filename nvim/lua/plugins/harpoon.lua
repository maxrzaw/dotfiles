local utils = require("mzawisa.utils")

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
                    return utils.find_project_root()
                end,
            },
            relative = {
                select = function(list_item, list, options)
                    default_config.select(list_item, list, options)
                end,
                get_root_dir = function()
                    return utils.find_project_root()
                end,
                equals = function(a, b)
                    return a.value == b.value
                end,
                create_list_item = function(_, item)
                    local path = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                    item = item or path
                    if string.sub(item, 1, 1) ~= "/" then
                        local dir = Path:new(path):parent().filename
                        path = dir .. "/" .. item
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
                        return utils.make_relative(ui_context, list_item.value, utils.find_project_root())
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

        -- vim.api.nvim_create_autocmd({ "QuitPre" }, {
        --     pattern = "*",
        --     callback = function()
        --         local bufnr = vim.api.nvim_get_current_buf()
        --         local path = vim.api.nvim_buf_get_name(bufnr)
        --         Harpoon.logger:log("QuitPre", bufnr, path)
        --         for _, it in ipairs(Harpoon:list().items) do
        --             local value = it.value
        --             if value == path then
        --                 Harpoon:list():append()
        --                 break
        --             end
        --         end
        --     end,
        -- })

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
