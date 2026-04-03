return {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    dependencies = {
        "williamboman/mason.nvim",
    },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
        broad_search = false,
    },
    config = function(_, opts)
        opts.silent = true
        require("roslyn").setup(opts)

        vim.lsp.config("roslyn", {
            settings = {
                ["csharp|formatting"] = {
                    dotnet_organize_imports_on_format = true,
                },
                ["csharp|completion"] = {
                    dotnet_show_completion_items_from_unimported_namespaces = true,
                    dotnet_show_name_completion_suggestions = true,
                },
            },
        })

        local fidget_notify = require("fidget.notification")
        local spinner = require("fidget.spinner")
        local dots = spinner.animate("dots", 1)
        local roslyn_initialized = false

        fidget_notify.set_config("roslyn", {
            name = "Roslyn",
            icon = function(now)
                if roslyn_initialized then
                    return "✔"
                end
                return dots(now)
            end,
            icon_style = "Question",
            ttl = math.huge,
        }, true)

        vim.api.nvim_create_autocmd("User", {
            pattern = "RoslynOnInit",
            callback = function(args)
                roslyn_initialized = false
                local target = args.data.target
                local name = type(target) == "string" and vim.fn.fnamemodify(target, ":t") or "project"
                require("fidget").notify("Initializing: " .. name, vim.log.levels.INFO, {
                    key = "roslyn_init",
                    group = "roslyn",
                })
            end,
        })

        vim.api.nvim_create_autocmd("User", {
            pattern = "RoslynInitialized",
            callback = function()
                roslyn_initialized = true
                local config = fidget_notify.options.configs["roslyn"]
                if config then
                    config.icon_style = "Constant"
                end
                require("fidget").notify("Initialized", vim.log.levels.INFO, {
                    key = "roslyn_init",
                    group = "roslyn",
                    ttl = 3,
                })
            end,
        })
    end,
}
