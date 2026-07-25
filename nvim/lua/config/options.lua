vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.wrap = false
vim.o.swapfile = false
vim.g.mapleader = ' '
vim.o.clipboard = 'unnamedplus'

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.winborder = 'rounded'

vim.o.completeopt = 'menu,menuone,noselect'

vim.o.splitright = true
vim.o.splitbelow = true

-- for tmux true color support
vim.o.termguicolors = true

-- colorscheme
vim.cmd.colorscheme("catppuccin-mocha")

-- treesitter indentation
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
