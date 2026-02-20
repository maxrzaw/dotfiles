return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            file_types = { "markdown" },
            sign = {
                enabled = false,
            },
            heading = {
                icons = {},
                backgrounds = {},
            },
            overrides = {
                buftype = {
                    nofile = { enabled = false },
                },
            },
        },
        cond = false,
    },
    {
        "iamcco/markdown-preview.nvim",
        name = "Markdown Preview",
        build = "cd app && npm install && git restore .",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
            if vim.fn.has("wsl") == 1 then
                vim.g.mkdp_browserfunc = "OpenBrowserWSL"
                vim.cmd([[
                    function! OpenBrowserWSL(url)
                        silent execute '!/mnt/c/Windows/System32/cmd.exe /c start "" ' .. shellescape(a:url)
                    endfunction
                ]])
            end
        end,
        ft = { "markdown" },
        config = function()
            -- options for markdown render
            -- mkit: markdown-it options for render
            -- katex: katex options for math
            -- uml: markdown-it-plantuml options
            -- maid: mermaid options
            -- disable_sync_scroll: if disable sync scroll, default 0
            -- sync_scroll_type: 'middle', 'top' or 'relative', default value is 'middle'
            --   middle: mean the cursor position alway show at the middle of the preview page
            --   top: mean the vim top viewport alway show at the top of the preview page
            --   relative: mean the cursor position alway show at the relative positon of the preview page
            -- hide_yaml_meta: if hide yaml metadata, default is 1
            -- sequence_diagrams: js-sequence-diagrams options
            -- content_editable: if enable content editable for preview page, default: v:false
            -- disable_filename: if disable filename header for preview page, default: 0
            vim.g.mkdp_preview_options = {
                mkit = {},
                katex = {},
                uml = {},
                maid = {},
                disable_sync_scroll = 0,
                sync_scroll_type = "middle",
                hide_yaml_meta = 1,
                sequence_diagrams = {},
                flowchart_diagrams = {},
                content_editable = false,
                disable_filename = 0,
                toc = {},
            }

            -- preview page title
            -- ${name} will be replace with the file name
            vim.g.mkdp_page_title = "「${name}」"

            -- recognized filetypes
            -- these filetypes will have MarkdownPreview... commands
            vim.g.mkdp_filetypes = { "markdown" }

            -- set default theme (dark or light)
            -- By default the theme is define according to the preferences of the system
            vim.g.mkdp_theme = "dark"
        end,
        cond = not vim.g.vscode,
    },
}
