local M = {}

local spinner_symbols = {
    "⠋",
    "⠙",
    "⠹",
    "⠸",
    "⠼",
    "⠴",
    "⠦",
    "⠧",
    "⠇",
    "⠏",
}

M._setup_done = false
M._processing = {}
M._spinner_index = 1
M._spinner_timer = nil

local spinner_interval = 120
local read_only_modes = {
    ["Claude Code"] = { "Plan" },
    ["Codex"] = { "Read Only" },
    ["OpenCode"] = { "plan" },
}

local function refresh_statusline()
    local ok, lualine = pcall(require, "lualine")
    if ok then
        lualine.refresh()
    end
end

local function has_processing()
    return next(M._processing) ~= nil
end

local function stop_spinner_timer()
    if not M._spinner_timer then
        return
    end

    M._spinner_timer:stop()
    M._spinner_timer:close()
    M._spinner_timer = nil
end

local function start_spinner_timer()
    if M._spinner_timer or not has_processing() then
        return
    end

    M._spinner_timer = assert(vim.uv.new_timer())
    M._spinner_timer:start(
        0,
        spinner_interval,
        vim.schedule_wrap(function()
            if not has_processing() then
                stop_spinner_timer()
                refresh_statusline()
                return
            end

            M._spinner_index = (M._spinner_index % #spinner_symbols) + 1
            refresh_statusline()
        end)
    )
end

local function current_metadata()
    if vim.bo.filetype ~= "codecompanion" then
        return nil
    end

    local metadata = rawget(_G, "codecompanion_chat_metadata")
    if type(metadata) ~= "table" then
        return nil
    end

    return metadata[vim.api.nvim_get_current_buf()]
end

local function current_mode(metadata)
    local mode = metadata and metadata.config_options and metadata.config_options.mode
    if type(mode) ~= "table" then
        return nil
    end

    return mode.name or mode.current
end

local function current_mode_value(metadata)
    local mode = metadata and metadata.config_options and metadata.config_options.mode
    if type(mode) ~= "table" then
        return nil
    end

    return mode.current
end

local function current_mode_name(metadata)
    local mode = metadata and metadata.config_options and metadata.config_options.mode
    if type(mode) ~= "table" then
        return nil
    end

    return mode.name
end

local function adapter_name(metadata)
    local adapter = metadata and metadata.adapter
    if type(adapter) ~= "table" then
        return nil
    end

    return adapter.name
end

local function contains(values, value)
    if not value then
        return false
    end

    for _, candidate in ipairs(values) do
        if candidate == value then
            return true
        end
    end

    return false
end

function M.setup()
    if M._setup_done then
        return
    end

    local group = vim.api.nvim_create_augroup("CodeCompanionStatusSpinner", { clear = true })

    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "CodeCompanionRequest*",
        callback = function(args)
            local data = args.data or {}
            local bufnr = data.bufnr
            if type(bufnr) == "number" then
                if args.match == "CodeCompanionRequestStarted" then
                    M._processing[bufnr] = true
                    start_spinner_timer()
                elseif args.match == "CodeCompanionRequestFinished" then
                    M._processing[bufnr] = nil
                    if not has_processing() then
                        stop_spinner_timer()
                    end
                end
            end

            refresh_statusline()
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = {
            "CodeCompanionChatOpened",
            "CodeCompanionChatClosed",
            "CodeCompanionChatModel",
            "CodeCompanionChatACPModeChanged",
        },
        callback = refresh_statusline,
    })

    M._setup_done = true
end

function M.lualine()
    local metadata = current_metadata()
    if not metadata then
        return ""
    end

    local parts = { "" }
    local bufnr = vim.api.nvim_get_current_buf()

    if M._processing[bufnr] then
        table.insert(parts, spinner_symbols[M._spinner_index])
    end

    local mode = current_mode(metadata)
    if mode then
        table.insert(parts, mode)
    end

    local adapter = metadata.adapter or {}
    if adapter.model then
        table.insert(parts, adapter.model)
    elseif adapter.name then
        table.insert(parts, adapter.name)
    end

    return table.concat(parts, " ")
end

function M.is_read_only_mode()
    local metadata = current_metadata()
    local mapping = read_only_modes[adapter_name(metadata)]
    if not mapping then
        return false
    end

    if contains(mapping, current_mode_value(metadata)) then
        return true
    end

    return contains(mapping, current_mode_name(metadata))
end

M.is_plan_mode = M.is_read_only_mode

return M
