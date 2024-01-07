local ls = require("luasnip")
local ls_choice = require("cmp_luasnip_choice")
ls_choice.setup({ auto_open = true })

require("luasnip.loaders.from_vscode").lazy_load()

-- Stolen from teej_dv
-- <c-j> is my expansion key
-- this will expand the current item or jump to the next item within the snippet.
vim.keymap.set({ "i", "s" }, "<c-j>", function()
    if ls.expand_or_jumpable() then
        ls.expand_or_jump()
    end
end, { silent = true, desc = "Expand the current snippet or jump to the next item within the snippet" })

-- <c-k> is my jump backwards key.
-- this always moves to the previous item within the snippet
vim.keymap.set({ "i", "s" }, "<c-k>", function()
    if ls.jumpable(-1) then
        ls.jump(-1)
    end
end, { silent = true, desc = "Move to the previous item within the snippet" })
