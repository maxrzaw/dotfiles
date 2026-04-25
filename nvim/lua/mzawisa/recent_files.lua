---@class RecentFilesPickerOpts
---@field mappings? table<string, table<string, fun(prompt_bufnr: number)>> Telescope-style per-mode mapping overrides for a single picker invocation.

---@class RecentFilesState
---@field loaded boolean
---@field setup_done boolean
---@field records table<string, RecentFileRecord>
---@field stale table<string, integer>
---@field config RecentFilesConfig
---@field compiled RecentFilesCompiledConfig

---@class RecentFilesModule
---@field open_picker fun(opts?: RecentFilesPickerOpts)
---@field setup fun(opts?: RecentFilesConfig)

---@type RecentFilesModule
local M = {}

local config_mod = require("mzawisa.recent_files.config")
local logic = require("mzawisa.recent_files.logic")
local path = require("mzawisa.recent_files.path")
local git_mod = require("mzawisa.recent_files.git")
local store_mod = require("mzawisa.recent_files.store")
local tracker_mod = require("mzawisa.recent_files.tracker")
local picker_mod = require("mzawisa.recent_files.picker")

---@type RecentFilesState
local state = {
    loaded = false,
    setup_done = false,
    records = {},
    stale = {},
    config = config_mod.defaults(),
    compiled = config_mod.compile(config_mod.defaults(), logic),
}

local store_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "mzawisa")
local store_path = vim.fs.joinpath(store_dir, "recent_files.json")

local store = store_mod.new({
    state = state,
    logic = logic,
    normalize_path = path.normalize,
    path_exists = path.exists,
    store_dir = store_dir,
    store_path = store_path,
})

local git = git_mod.new({
    state = state,
    logic = logic,
    normalize_path = path.normalize,
    path_exists = path.exists,
    mark_stale = store.mark_stale,
})

local tracker = tracker_mod.new({
    state = state,
    logic = logic,
    normalize_path = path.normalize,
    path_exists = path.exists,
    get_git_info = git.get_git_info,
    load_records = store.load_records,
})

local picker = picker_mod.new({
    logic = logic,
    load_records = store.load_records,
    sorted_records = store.sorted_records,
    current_context = git.current_context,
    resolve_record_target = git.resolve_record_target,
    should_ignore_record = tracker.should_ignore_record,
    normalize_path = path.normalize,
    get_config = function()
        return state.config
    end,
})

---@param opts? RecentFilesPickerOpts
function M.open_picker(opts)
    return picker.open_picker(opts)
end

---@param opts? RecentFilesConfig
function M.setup(opts)
    state.config = config_mod.merge(state.config, opts)
    state.compiled = config_mod.compile(state.config, logic)

    if state.setup_done then
        return
    end

    store.load_records()

    local group = vim.api.nvim_create_augroup("mzawisa_recent_files", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = group,
        callback = tracker.record_current_buffer,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            store.save_records()
        end,
    })

    state.setup_done = true
end

return M
