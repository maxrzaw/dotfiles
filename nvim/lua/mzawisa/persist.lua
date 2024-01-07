local utils = require("mzawisa.utils")
local Path = require("plenary.path")
--- Ensure that the data directory exists
Path:new(vim.fn.stdpath("data") .. "/mzawisa"):mkdir({ parents = true, exists_ok = true })

---@class PersistOptions
---@field keyfunc fun():string

---@class PersistPartialOptions
---@field keyfunc? fun():string

---@class Persist
---@field opts PersistOptions
---@field data {[string]: {[string]: boolean}}
local Persist = {}

Persist.__index = Persist

--- Get the value of a key
---@param key string
---@return boolean|nil
function Persist:get(key)
    if self.data[self.opts.keyfunc()] == nil then
        self.data[self.opts.keyfunc()] = {}
    end
    if self.data[self.opts.keyfunc()][key] == nil then
        return nil
    end
    return self.data[self.opts.keyfunc()][key]
end

--- Set the value of the key
---@param key string
---@param value boolean
function Persist:set(key, value)
    self.data[self.opts.keyfunc()][key] = value
end

--- Clear the value of the key
---@param key string
function Persist:clear(key)
    self.data[self.opts.keyfunc()][key] = nil
end

--- Clears all the values for the current `keyfunc()`
function Persist:clear_all()
    self.data[self.opts.keyfunc()] = {}
end

--- Write the data to the backing file
---@param data any
local function write_data(data)
    Path:new(vim.fn.stdpath("data") .. "/mzawisa/persist.json"):write(vim.json.encode(data), "w")
end

--- Read the data from the backing file
---@return {[string]: {[string]: boolean}}
local function read_data()
    local path = Path:new(vim.fn.stdpath("data") .. "/mzawisa/persist.json")
    local exists = path:exists()

    if not exists then
        write_data({})
    end

    local out_data = path:read()

    if not out_data or out_data == "" then
        write_data({})
        out_data = path:read()
    end

    local data = vim.json.decode(out_data)
    return data
end

--- Sync the data to the backing file
function Persist:sync()
    local ok, data = pcall(read_data)
    if not ok then
        error("Persist#sync: Failed to load data")
        return
    end

    for key, value in pairs(self.data) do
        data[key] = value
    end

    ok = pcall(write_data, data)
end

--- Load the data from the backing file
---@return {[string]: {[string]: boolean}}
local function load()
    local ok, data = pcall(read_data)
    if not ok then
        data = {}
    end

    return data
end

--- Create a new instance of Persist
---@return Persist
function Persist:new()
    local data = load()
    local persist = setmetatable({
        opts = {
            keyfunc = function()
                return utils.find_project_root()
            end,
        },
        data = data,
    }, self)

    return persist
end

local instance = Persist:new()

--- Setup the instance
---@param opts PersistPartialOptions
function Persist:setup(opts)
    if self ~= instance then
        error("Persist:setup must be called on the instance")
    end
    self.opts = vim.tbl_deep_extend("force", self.opts, opts or {})
end

return instance
