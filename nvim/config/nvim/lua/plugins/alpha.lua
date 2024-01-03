return {
    {
        cond = false,
        "goolord/alpha-nvim",
        dependencies = {
            "nvim-telescope/telescope-file-browser.nvim",
            "lazy.nvim",
            "nvim-neo-tree/neo-tree.nvim",
        },
        lazy = true,
        event = "VimEnter",
        opts = function()
            local dashboard = require("alpha.themes.dashboard")
            local logo = [[
   ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
   ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
   ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
   ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
   ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
   ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

    ]]

            local function getGreeting(name)
                local tableTime = os.date("*t")
                local datetime = os.date(" %Y-%m-%d   %H:%M:%S")
                local hour = tableTime.hour
                local greetingsTable = {
                    [1] = "  Sleep well",
                    [2] = "  Good morning",
                    [3] = "  Good afternoon",
                    [4] = "  Good evening",
                    [5] = "󰖔  Good night",
                }
                local greetingIndex = 0
                if hour == 23 or hour < 7 then
                    greetingIndex = 1
                elseif hour < 12 then
                    greetingIndex = 2
                elseif hour >= 12 and hour < 18 then
                    greetingIndex = 3
                elseif hour >= 18 and hour < 21 then
                    greetingIndex = 4
                elseif hour >= 21 then
                    greetingIndex = 5
                end
                return "\t" .. datetime .. "\t" .. greetingsTable[greetingIndex] .. ", " .. name
            end

            local userName = "Max"
            local greeting = getGreeting(userName)
            dashboard.section.header.val = vim.split(logo .. "\n" .. greeting, "\n")
            dashboard.section.buttons.val = {
                dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
                dashboard.button("e", "󰙅 " .. " File browser", ":Neotree<CR>"),
                dashboard.button("r", "󰄉 " .. " Recent files", ":Telescope oldfiles <CR>"),
                dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
                dashboard.button("g", "󱎸 " .. " Find text", ":Telescope live_grep <CR>"),
                dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
                dashboard.button("m", "󰢷 " .. " Mason", ":Mason<CR>"),
                dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
                dashboard.button("q", " " .. " Quit", ":qa<CR>"),
            }

            dashboard.section.footer.val = require("alpha.fortune")

            -- set highlight
            for _, button in ipairs(dashboard.section.buttons.val) do
                button.opts.hl = "AlphaButtons"
                button.opts.hl_shortcut = "AlphaShortcut"
            end
            dashboard.section.header.opts.hl = "AlphaHeader"
            dashboard.section.buttons.opts.hl = "AlphaButtons"
            dashboard.section.footer.opts.hl = "AlphaFooter"
            dashboard.opts.layout[1].val = 8
            return dashboard
        end,
        config = function(_, dashboard)
            -- close Lazy and re-open when the dashboard is ready
            if vim.o.filetype == "lazy" then
                vim.cmd.close()
                vim.api.nvim_create_autocmd("User", {
                    pattern = "AlphaReady",
                    callback = function()
                        require("lazy").show()
                    end,
                })
            end

            require("alpha").setup(dashboard.opts)

            vim.api.nvim_create_autocmd("User", {
                pattern = "LazyVimStarted",
                callback = function()
                    local stats = require("lazy").stats()
                    local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
                    local version = "  󰥱 v"
                        .. vim.version().major
                        .. "."
                        .. vim.version().minor
                        .. "."
                        .. vim.version().patch

                    local plugins = "⚡Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
                    local footer = vim.split(version .. "\t" .. plugins .. "\n", "\n")

                    local fortune = require("alpha.fortune")()
                    for _, v in ipairs(fortune) do
                        table.insert(footer, v)
                    end

                    dashboard.section.footer.val = footer
                    pcall(vim.cmd.AlphaRedraw)
                end,
            })
        end,
    },
}
