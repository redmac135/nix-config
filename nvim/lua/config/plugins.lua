vim.pack.add({
	-- snacks
	"https://github.com/folke/snacks.nvim",

	-- colorscheme
	"https://github.com/vague2k/vague.nvim",

	-- oil: file explorer
	"https://github.com/stevearc/oil.nvim",

	-- lsp, formatting
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/stevearc/conform.nvim",

	-- mini suite
	"https://github.com/nvim-mini/mini.comment",
	"https://github.com/nvim-mini/mini.icons",
	"https://github.com/nvim-mini/mini.pairs",

	-- treesitter & autotags
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
	"https://github.com/windwp/nvim-ts-autotag",

	-- autocompletion & snippets
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/rafamadriz/friendly-snippets",
})

vim.cmd("colorscheme vague")
