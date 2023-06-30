local M = {};

local function bind(op, outer_opts)
    outer_opts = outer_opts or { noremap = true, silent = true };
    return function(lhs, rhs, opts)
        opts = vim.tbl_extend("force", outer_opts, opts or {});
        vim.keymap.set(op, lhs, rhs, opts);
    end
end

M.imap = bind("i", { noremap = false });
M.nmap = bind("n", { noremap = false });
M.omap = bind("o", { noremap = false });
M.smap = bind("s", { noremap = false });
M.xmap = bind("x", { noremap = false });
M.inoremap = bind("i");
M.nnoremap = bind("n");
M.snoremap = bind("s");
M.vnoremap = bind("v");
M.xnoremap = bind("x");

return M;
