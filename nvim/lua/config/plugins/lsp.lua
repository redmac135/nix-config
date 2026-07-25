-- Diagnostics
vim.diagnostic.config({
	virtual_text = {
		prefix = '●',
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

-- Global LSP capabilities from nvim-cmp
vim.lsp.config('*', {
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

-- Enable all servers
vim.lsp.enable({
	"bashls",
	"clangd",
	"cmake",
	"cssls",
	"denols",
	"dockerls",
	"gopls",
	"html",
	"lua_ls",
	"nil_ls",
	"pyright",
	"rust_analyzer",
	"ts_ls",
	"yamlls",
})
