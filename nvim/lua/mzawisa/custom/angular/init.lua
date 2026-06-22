local M = {}
M.enabled = false

local function load_file_into_buffer(file)
    -- Just use :edit. It reuses an already-loaded buffer for the file if one exists, and unlike the
    -- previous nvim_win_set_buf + execute("edit") dance it sequences the buffer swap and LSP detach
    -- correctly, avoiding "E1159: Cannot open a float when closing the buffer" during the redraw.
    vim.cmd.edit(vim.fn.fnameescape(file))
end

local function get_destination_without_extension()
    local current_buffer = vim.api.nvim_buf_get_name(0)
    -- Use fnamemodify for both the directory (":p:h" = absolute head) and the filename (":t" = tail).
    -- These are separator-aware and handle absolute, relative, and forward-slash paths on every OS,
    -- which plenary's :parent() / join did not do reliably on Windows.
    local dir = vim.fn.fnamemodify(current_buffer, ":p:h")
    local filename = vim.fn.fnamemodify(current_buffer, ":t")

    local filename_without_ext = nil
    if string.match(filename, "%.html$") then
        filename_without_ext = string.match(filename, "(.-)%.html$")
    elseif string.match(filename, "%.spec%.ts$") then
        filename_without_ext = string.match(filename, "(.-)%.spec%.ts$")
    elseif string.match(filename, "%.ts$") then
        filename_without_ext = string.match(filename, "(.-)%.ts$")
    elseif string.match(filename, "%.scss$") then
        filename_without_ext = string.match(filename, "(.-)%.scss$")
    end

    -- Join with "/": Neovim (filereadable, vim.uri_from_fname, :edit) accepts forward slashes on
    -- Windows too, so this stays correct cross-platform without manual separator handling.
    return dir .. "/" .. filename_without_ext
end

local function go_to_file_with_ext(ext)
    local full_destination = get_destination_without_extension() .. ext

    local exists = vim.fn.filereadable(full_destination)
    -- don't open a buffer if the file doesn't exist since you may end up creating a file without knowing it
    if exists == 0 then
        vim.notify("File doesn't exist: " .. full_destination, vim.log.levels.WARN)
        return
    end

    load_file_into_buffer(full_destination)
end

function M.go_to_template_file()
    go_to_file_with_ext(".html")
end
function M.go_to_spec_file()
    go_to_file_with_ext(".spec.ts")
end
function M.go_to_component_file()
    go_to_file_with_ext(".ts")
end
function M.go_to_style_file()
    go_to_file_with_ext(".scss")
end

function M.set_quickswitch_keybindings()
    vim.keymap.set("n", "<leader>sp", M.go_to_spec_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Angular: Go to [Sp]ec",
    })
    vim.keymap.set("n", "<leader>ss", M.go_to_style_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Angular: Go to [S]tyle [S]heet",
    })
    vim.keymap.set("n", "<leader>tt", M.go_to_template_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Angular: Go to [T]emplate",
    })
    vim.keymap.set("n", "<leader>ts", M.go_to_component_file, {
        silent = true,
        noremap = true,
        buffer = true,
        desc = "Angular: Go to [T]ype[S]cript Component",
    })
end

function M.setup()
    M.enabled = true
    vim.lsp.enable("angularls")
    vim.api.nvim_create_autocmd(
        { "BufWinEnter" },
        { pattern = { "*.ts", "*.html", "*.scss", "*.htmlangular" }, callback = M.set_quickswitch_keybindings }
    )
end

return M
