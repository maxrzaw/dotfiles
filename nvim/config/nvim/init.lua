-- My First Neovim config
if vim.g.vscode then
    require('mzawisa.vscode')
else
    require('mzawisa')
end
