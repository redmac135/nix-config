vim.pack.add({
	-- snacks
	"https://github.com/folke/snacks.nvim",

	-- colorscheme
	"https://github.com/vague2k/vague.nvim",

	-- oil: file explorer
	"https://github.com/stevearc/oil.nvim",

	-- lsp, autocompletion, snippets, commenting, autopairs
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/nvim-mini/mini.comment",
	"https://github.com/nvim-mini/mini.icons",
	"https://github.com/nvim-mini/mini.pairs",
	"https://github.com/stevearc/conform.nvim",

	-- treesitter
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },

	-- snippets
	"https://github.com/rafamadriz/friendly-snippets",

	-- nvim-ts-autotag and autopairs
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/windwp/nvim-autopairs",

	-- autocompletion
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/L3MON4D3/LuaSnip",
})

vim.cmd("colorscheme vague")
