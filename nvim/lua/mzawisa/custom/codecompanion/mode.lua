local M = {}

local function get_chat()
    local ok, codecompanion = pcall(require, "codecompanion")
    if not ok then
        return nil
    end

    return codecompanion.buf_get_chat(vim.api.nvim_get_current_buf()) or codecompanion.last_chat()
end

function M.select_mode()
    local chat = get_chat()
    if not chat then
        vim.notify("No CodeCompanion chat available", vim.log.levels.WARN)
        return
    end

    if not chat.acp_connection then
        vim.notify("Current CodeCompanion chat is not using an ACP adapter", vim.log.levels.WARN)
        return
    end

    local mode_option
    for _, option in ipairs(chat.acp_connection:get_config_options() or {}) do
        if option.type == "select" and (option.category == "mode" or option.id == "mode") then
            mode_option = option
            break
        end
    end

    if not mode_option then
        vim.notify("No ACP mode options available for this chat", vim.log.levels.WARN)
        return
    end

    local values = require("codecompanion.acp").flatten_config_options(mode_option.options or {})
    if #values == 0 then
        vim.notify("No ACP modes available for this chat", vim.log.levels.WARN)
        return
    end

    local choices = {}
    local choice_map = {}

    for i, value in ipairs(values) do
        local prefix = value.value == mode_option.currentValue and "* " or "  "
        local label = prefix .. value.name
        if value.description then
            label = label .. " - " .. value.description
        end

        choices[i] = label
        choice_map[i] = value
    end

    vim.ui.select(choices, {
        kind = "codecompanion.nvim",
        prompt = "CodeCompanion Mode",
    }, function(_, idx)
        if not idx then
            return
        end

        local selected = choice_map[idx]
        if selected.value == mode_option.currentValue then
            return
        end

        local ok = chat.acp_connection:set_config_option(mode_option.id, selected.value)
        if not ok then
            vim.notify("Failed to change CodeCompanion mode", vim.log.levels.ERROR)
            return
        end

        if chat.update_metadata then
            chat:update_metadata()
        end
    end)
end

return M
