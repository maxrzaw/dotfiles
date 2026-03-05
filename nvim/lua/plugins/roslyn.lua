return {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    dependencies = {
        "williamboman/mason.nvim",
    },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
        broad_search = true,
    },
    config = function(_, opts)
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
    end,
}
