local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.pyright.setup({
	capabilities = capabilities,
	single_file_support = true,
})

vim.treesitter.start()
