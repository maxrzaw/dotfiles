local utils = require("mzawisa.utils")

return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dev = false,
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local Path = require("plenary.path")
        local function normalize_path(buf_name, root)
            return Path:new(buf_name):make_relative(root)
        end
        local Harpoon = require("harpoon")
        local Logger = require("harpoon.logger")
        local Extensions = require("harpoon.extensions")
        local default_config = Harpoon.config.default

        Harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = function()
                    -- return vim.uv.cwd() -- This is the default
                    return utils.find_project_root()
                end,
            },
            default = {

                --- select_with_nill allows for a list to call select even if the provided item is nil
                select_with_nil = false,

                encode = function(obj)
                    return vim.json.encode(obj)
                end,

                decode = function(str)
                    return vim.json.decode(str)
                end,

                display = function(list_item)
                    return normalize_path(list_item.value, vim.loop.cwd())
                end,

                select = function(list_item, list, options)
                    Logger:log("config_default#select", list_item, list.name, options)
                    options = options or {}
                    if list_item == nil then
                        return
                    end

                    local bufnr = vim.fn.bufnr(list_item.value)
                    local set_position = false
                    if bufnr == -1 then
                        set_position = true
                        bufnr = vim.fn.bufnr(list_item.value, true)
                    end
                    if bufnr == nil then
                        error("bufnr was actually nil and not -1")
                        return
                    end
                    if not vim.api.nvim_buf_is_loaded(bufnr) then
                        vim.fn.bufload(bufnr)
                        vim.api.nvim_set_option_value("buflisted", true, {
                            buf = bufnr,
                        })
                    end

                    if options.vsplit then
                        vim.cmd("vsplit")
                    elseif options.split then
                        vim.cmd("split")
                    elseif options.tabedit then
                        vim.cmd("tabedit")
                    end

                    vim.api.nvim_set_current_buf(bufnr)

                    if set_position then
                        vim.api.nvim_win_set_cursor(0, {
                            list_item.context.row or 1,
                            list_item.context.col or 0,
                        })
                    end

                    Extensions.extensions:emit(Extensions.event_names.NAVIGATE, {
                        buffer = bufnr,
                    })
                end,

                equals = function(list_item_a, list_item_b)
                    return list_item_a.value == list_item_b.value
                end,

                get_root_dir = function()
                    return vim.loop.cwd()
                end,

                create_list_item = function(_, item)
                    if item == nil then
                        item = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                    end

                    if type(item) == "string" then
                        local name = Path:new(item):absolute()
                        local bufnr = vim.fn.bufnr(name, false)

                        local pos = { 1, 0 }
                        if bufnr ~= -1 then
                            pos = vim.api.nvim_win_get_cursor(0)
                        end
                        item = {
                            value = name,
                            context = {
                                row = pos[1],
                                col = pos[2],
                            },
                        }
                    end

                    Logger:log("config_default#create_list_item", item)

                    return item
                end,

                BufLeave = function(arg, list)
                    local bufnr = arg.buf
                    local bufname = vim.api.nvim_buf_get_name(bufnr)
                    local item = nil
                    for _, it in ipairs(list.items) do
                        local value = it.value
                        if value == bufname then
                            item = it
                            break
                        end
                    end
                    if item then
                        local pos = vim.api.nvim_win_get_cursor(0)

                        Logger:log(
                            "config_default#BufLeave updating position",
                            bufnr,
                            bufname,
                            item,
                            "to position",
                            pos
                        )

                        item.context.row = pos[1]
                        item.context.col = pos[2]
                    end
                end,

                autocmds = { "BufLeave" },
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
